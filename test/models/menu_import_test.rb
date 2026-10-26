require "test_helper"

class MenuImportTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 10, 27, 12, 0)
    @merchant = create(:merchant, :food_and_drink)
  end

  def build_import(**attrs)
    MenuImport.new(@merchant, { food_text: "雞腿飯 90\n排骨飯 85", drink_text: "紅茶 30", menu_date: "2026-10-20" }.merge(attrs))
  end

  test "有效的匯入：餐食與飲料各自標上類別" do
    import = build_import

    assert import.valid?
    assert_equal(
      [ [ "food", "雞腿飯", 90 ], [ "food", "排骨飯", 85 ], [ "drink", "紅茶", 30 ] ],
      import.rows.map { |row| [ row.category, row.name, row.price ] }
    )
    assert(import.rows.all? { |row| row.action == :new })
  end

  test "只貼其中一種也可以" do
    assert build_import(drink_text: "").valid?
    assert build_import(food_text: nil).valid?
  end

  test "什麼都沒貼：不可匯入" do
    import = build_import(food_text: "", drink_text: " \n ")

    assert_not import.valid?
    assert_includes import.errors[:base], "請至少貼上一段菜單（餐食或飲料）"
  end

  test "菜單日期必填，且不預設為今天" do
    import = build_import(menu_date: nil)

    assert_not import.valid?
    assert import.errors.of_kind?(:menu_date, :blank)
    assert_nil MenuImport.new(@merchant).menu_date
  end

  test "菜單日期不可晚於今天，但可以是很久以前（會被標為過期）" do
    assert_not build_import(menu_date: "2026-10-28").valid?
    assert build_import(menu_date: "2025-01-01").valid?
  end

  test "日期格式錯誤視為沒填" do
    assert_not build_import(menu_date: "不是日期").valid?
  end

  test "解析失敗的行會以行號回報在對應的欄位" do
    import = build_import(food_text: "雞腿飯 90\n今日特餐\n排骨飯 85", drink_text: "紅茶")

    assert_not import.valid?
    assert_includes import.errors[:food_text].first, "第 2 行「今日特餐」：找不到價格"
    assert_includes import.errors[:drink_text].first, "第 1 行「紅茶」：找不到價格"
  end

  test "同一段文字內品名重複會報錯" do
    import = build_import(food_text: "雞腿飯 90\n雞腿飯 95")

    assert_not import.valid?
    assert_match(/重複/, import.errors[:food_text].first)
  end

  test "餐食與飲料可以有同名項目（類別不同）" do
    assert build_import(food_text: "茶 50", drink_text: "茶 30").valid?
  end

  test "文字過長不可匯入" do
    assert_not build_import(food_text: "a" * 5_001).valid?
  end

  test "品項超過 100 個不可匯入" do
    text = (1..101).map { |n| "品項#{n.to_s.tr('0-9', 'ABCDEFGHIJ')} #{n}" }.join("\n")

    import = build_import(food_text: text, drink_text: "")

    assert_not import.valid?
    assert_includes import.errors[:base], "一次最多匯入 100 個品項"
  end

  test "同店同類別同品名已存在：標示為更新並帶出原價" do
    create(:menu_item, merchant: @merchant, name: "雞腿飯", category: "food", price: 85)

    rows = build_import.rows

    assert_equal [ :update, 85 ], [ rows.first.action, rows.first.old_price ]
    assert_equal :new, rows.last.action
  end

  test "存檔：建立項目並套用整批共用的菜單日期" do
    assert_equal 3, build_import.save

    items = @merchant.menu_items.reload
    assert_equal 3, items.size
    assert_equal [ Date.new(2026, 10, 20) ], items.map(&:menu_date).uniq
    assert_equal "drink", items.find_by(name: "紅茶").category
  end

  test "存檔：已存在的項目更新價格與日期，不會重複建立" do
    existing = create(:menu_item, merchant: @merchant, name: "雞腿飯", category: "food", price: 85, menu_date: Date.new(2026, 5, 1))

    assert_difference "MenuItem.count", 2 do
      build_import.save
    end

    assert_equal [ 90, Date.new(2026, 10, 20) ], existing.reload.then { |item| [ item.price, item.menu_date ] }
  end

  test "每月更新：重複匯入同一份菜單不會增加項目" do
    build_import.save

    assert_no_difference "MenuItem.count" do
      build_import(menu_date: "2026-10-27").save
    end
  end

  test "驗證失敗時什麼都不寫入（即使有些行是對的）" do
    import = build_import(food_text: "雞腿飯 90\n今日特餐")

    assert_no_difference "MenuItem.count" do
      assert_equal false, import.save
    end
  end

  test "存檔會更新店家的 updated_at（列表依最近更新排序）" do
    @merchant.update_column(:updated_at, 3.days.ago)

    build_import.save

    assert_in_delta Time.current, @merchant.reload.updated_at, 5
  end

  test "存檔後菜單即為有效（120 天內）" do
    build_import.save

    assert(@merchant.menu_items.reload.all?(&:orderable?))
  end
end
