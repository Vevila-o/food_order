require "test_helper"

class InquiryFormTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 10, 22, 12, 0) # 先固定時間，之後建立的菜單日期才不會是「未來」
    AppSetting.instance
    @event = create(:event, :with_headcount, held_on: Date.new(2026, 10, 27), headcount: 18)
    @merchant = create(:merchant, :food_and_drink, delivery_fee: 60, free_delivery_threshold: 1500)
    @food = create(:menu_item, merchant: @merchant, name: "雞腿便當", price: 90, unit: "份")
    @drink = create(:menu_item, :drink, merchant: @merchant, name: "紅茶", price: 30, unit: "杯")
  end

  def form(quantities, merchant: @merchant, event: @event) = InquiryForm.new(event: event, merchant: merchant, quantities: quantities)

  # --- 可選品項 ---

  test "可選品項：菜單有效的，餐食在前；過期與日期不明的另列" do
    stale = create(:menu_item, :stale, merchant: @merchant, name: "舊菜")
    unknown = create(:menu_item, :date_unknown, merchant: @merchant, name: "不明")

    f = form({})

    assert_equal [ @food, @drink ], f.orderable_items
    assert_equal [ stale, unknown ].sort_by(&:name), f.unavailable_items
  end

  # --- 金額 ---

  test "小計、外送費、預計金額由伺服器用菜單單價重算" do
    f = form({ @food.id.to_s => "10", @drink.id.to_s => "10" })

    assert_equal 1200, f.pricing.subtotal
    assert_equal 60, f.pricing.delivery_fee
    assert_equal 1260, f.pricing.total
    assert_equal 20, f.total_quantity
  end

  test "滿額免運" do
    f = form({ @food.id.to_s => "18" }) # 1620 ≥ 1500

    assert_equal 0, f.pricing.delivery_fee
    assert_equal 1620, f.pricing.total
  end

  test "外送費未知：預計金額也是 nil，不當 0" do
    @merchant.update!(delivery_fee: nil, free_delivery_threshold: nil)

    f = form({ @food.id.to_s => "5" })

    assert_nil f.pricing.delivery_fee
    assert_nil f.pricing.total
    assert_equal 450, f.pricing.subtotal
  end

  test "訊息與金額同源：單位、小計都在訊息裡" do
    f = form({ @food.id.to_s => "18" })

    assert_includes f.message, "- 雞腿便當 × 18 份"
    assert_includes f.message, "NT$1,620"
    assert_includes f.message, "PicCollage 公司總部（台北市大安區光復南路 102 號 3 樓）"
    assert_not_includes f.message, "收件人"
  end

  test "設定頁有填收件人與電話才寫進訊息" do
    AppSetting.instance.update!(recipient_name: "王小明", recipient_phone: "0912-345-678")

    assert_includes form({ @food.id.to_s => "1" }).message, "收件人：王小明，電話：0912-345-678"
  end

  # --- 預算 ---

  test "預算：只算這一家，不含本場其他店家的詢問單" do
    other = create(:merchant)
    create(:order_inquiry, event: @event, merchant: other, subtotal: 500, delivery_fee: 0, total: 500)

    f = form({ @food.id.to_s => "10" }) # 900 + 60 = 960

    assert_equal 960, f.budget.known_total
    assert_equal 1800, f.budget.total_budget
    assert_equal :room, f.budget.status
  end

  test "預算：超出 NT$100 × 人數" do
    f = form({ @food.id.to_s => "18", @drink.id.to_s => "18" }) # 2160

    assert_equal :over, f.budget.status
  end

  test "預算：已存的這張不會重複計算（會被覆蓋）" do
    form({ @food.id.to_s => "10" }).save

    f = form({ @food.id.to_s => "10" })

    assert_equal 960, f.budget.known_total
  end

  # --- 輸入驗證 ---

  test "沒有選任何品項：不能存" do
    f = form({})

    assert_not f.valid?
    assert_includes f.errors.full_messages, "請至少選一項餐點"
  end

  test "數量必須是 0 到 99 的整數" do
    [ "-1", "100", "abc", "1.5", "1e2" ].each do |value|
      f = form({ @food.id.to_s => value })

      assert_not f.valid?, value
      assert_match(/數量必須是 0 到 99/, f.errors.full_messages.join, value)
      assert_not f.any_lines?, value
    end
  end

  test "空白數量當 0；數量 99 可以" do
    assert form({ @food.id.to_s => "99", @drink.id.to_s => "" }).valid?
  end

  test "過期或日期不明的品項不能選" do
    stale = create(:menu_item, :stale, merchant: @merchant, name: "舊菜", price: 10)

    f = form({ @food.id.to_s => "1", stale.id.to_s => "2" })

    assert_not f.valid?
    assert_match(/「舊菜」的菜單日期已過期或不明/, f.errors.full_messages.join)
    assert_not_includes f.lines.map(&:menu_item), stale
  end

  test "別間店的品項、不存在的 id 直接忽略，不影響金額" do
    foreign = create(:menu_item, price: 1000)

    f = form({ @food.id.to_s => "1", foreign.id.to_s => "5", "999999" => "3", "abc" => "1" })

    assert f.valid?
    assert_equal 90, f.pricing.subtotal
  end

  test "單價取自菜單，不接受前端帶的價格" do
    f = form({ @food.id.to_s => "2", "price" => "1" })

    assert_equal 180, f.pricing.subtotal
  end

  # --- 活動與人數 ---

  test "沒有活動：被擋下" do
    f = form({ @food.id.to_s => "1" }, event: nil)

    assert_equal :no_event, f.blocked_reason
    assert_not f.valid?
  end

  test "沒有人數：被擋下，不用 0 人算預算" do
    event = create(:event, held_on: Date.new(2026, 11, 24))

    f = form({ @food.id.to_s => "1" }, event: event)

    assert_equal :no_headcount, f.blocked_reason
    assert_not f.valid?
    assert_match(/報名人數/, f.errors.full_messages.join)
  end

  test "活動日期已過仍可使用（不擋）" do
    travel_to Time.zone.local(2026, 12, 1) do
      assert form({ @food.id.to_s => "1" }).valid?
    end
  end

  # --- 儲存 ---

  test "儲存：建立詢問單與品項快照，狀態是草稿，人數與金額為當下的值" do
    inquiry = nil
    assert_difference [ "OrderInquiry.count" ], 1 do
      inquiry = form({ @food.id.to_s => "10", @drink.id.to_s => "8" }).save
    end

    assert inquiry.draft?
    assert_equal 18, inquiry.headcount_at_creation
    assert_equal 1140, inquiry.subtotal
    assert_equal 60, inquiry.delivery_fee
    assert_equal 1200, inquiry.total
    assert_includes inquiry.message_text, "- 雞腿便當 × 10 份"
    assert_equal [ [ "雞腿便當", "份", 10, 90 ], [ "紅茶", "杯", 8, 30 ] ],
                 inquiry.items.order(:id).pluck(:name, :unit, :quantity, :unit_price)
  end

  test "儲存的訊息就是畫面預覽的訊息" do
    f = form({ @food.id.to_s => "10" })

    assert_equal f.message, f.save.message_text
  end

  test "再次儲存：覆蓋同一張詢問單，不新增、品項整批換掉" do
    first = form({ @food.id.to_s => "10" }).save

    assert_no_difference "OrderInquiry.count" do
      @second = form({ @drink.id.to_s => "5" }).save
    end

    assert_equal first.id, @second.id
    assert_equal [ "紅茶" ], @second.items.reload.map(&:name)
    assert_equal 150, @second.subtotal
  end

  test "儲存後菜單改價，不影響歷史快照" do
    inquiry = form({ @food.id.to_s => "2" }).save

    @food.update!(price: 999, name: "改名")

    item = inquiry.items.reload.first
    assert_equal [ "雞腿便當", 90 ], [ item.name, item.unit_price ]
  end

  test "帶 channel 儲存：標為已詢問並記錄管道" do
    inquiry = form({ @food.id.to_s => "1" }).save(channel: :line)

    assert inquiry.sent?
    assert inquiry.via_line?
    assert_not_nil inquiry.sent_at
  end

  test "已詢問的再存草稿：狀態不會被降回草稿" do
    form({ @food.id.to_s => "1" }).save(channel: :line)

    inquiry = form({ @food.id.to_s => "2" }).save

    assert inquiry.sent?
  end

  test "已確認訂購的詢問單不能再改" do
    inquiry = form({ @food.id.to_s => "1" }).save
    inquiry.confirm!

    f = form({ @food.id.to_s => "5" })

    assert_not f.save
    assert_match(/已確認訂購/, f.errors.full_messages.join)
    assert_equal 1, inquiry.reload.items.first.quantity
  end

  test "驗證失敗什麼都不寫入" do
    assert_no_difference [ "OrderInquiry.count", "OrderInquiryItem.count" ] do
      assert_not form({ @food.id.to_s => "abc" }).save
    end
  end

  test "已有詢問單時，沒給數量就用既有品項當預設" do
    form({ @food.id.to_s => "7", @drink.id.to_s => "3" }).save

    f = InquiryForm.new(event: @event, merchant: @merchant)

    assert_equal 7, f.quantity_for(@food)
    assert_equal 3, f.quantity_for(@drink)
  end

  test "給了數量（即使是空的）就不套用既有品項" do
    form({ @food.id.to_s => "7" }).save

    assert_equal 0, form({}).quantity_for(@food)
  end

  test "菜單項目被刪掉：既有詢問單的快照仍在，預設數量只帶還存在的品項" do
    form({ @food.id.to_s => "7" }).save
    @food.destroy!
    @merchant.reload

    f = InquiryForm.new(event: @event, merchant: @merchant)

    assert_equal [ @drink ], f.orderable_items
    assert_equal 0, f.quantity_for(@drink)
    assert_equal [ "雞腿便當" ], OrderInquiry.last.items.map(&:name)
  end

  test "飲料店（只賣飲料）也能產生詢問單" do
    shop = create(:merchant, :drink_only, delivery_fee: 0)
    bucket = create(:menu_item, :drink, merchant: shop, name: "冬瓜茶", price: 280, unit: "桶")

    inquiry = form({ bucket.id.to_s => "2" }, merchant: shop).save

    assert_equal 560, inquiry.total
    assert_includes inquiry.message_text, "- 冬瓜茶 × 2 桶"
  end
end
