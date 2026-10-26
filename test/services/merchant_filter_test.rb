require "test_helper"

class MerchantFilterTest < ActiveSupport::TestCase
  # budget 以外的關鍵字都是篩選參數
  def names(budget: nil, **params)
    MerchantFilter.new(params, budget: budget).merchants.map(&:name)
  end

  # --- 預設 ---

  test "沒有條件：列出全部店家，預設排序收藏優先再依最近更新" do
    create(:merchant, name: "舊店").update_column(:updated_at, 3.days.ago)
    create(:merchant, name: "新店")
    favorite = create(:merchant, name: "收藏店", favorited: true)
    favorite.update_column(:updated_at, 10.days.ago)

    assert_equal [ "收藏店", "新店", "舊店" ], names
    assert_not MerchantFilter.new.active?
    assert_equal 0, MerchantFilter.new.active_count
  end

  test "沒有店家時回傳空陣列" do
    assert_empty names
  end

  # --- 類型 ---

  test "類型：餐＋飲 / 只有餐 / 僅飲料" do
    create(:merchant, name: "餐飲", offers_drink: true)
    create(:merchant, name: "只有餐")
    create(:merchant, :drink_only, name: "僅飲料")

    assert_equal [ "餐飲" ], names(kinds: [ "food_and_drink" ])
    assert_equal [ "只有餐" ], names(kinds: [ "food_only" ])
    assert_equal [ "僅飲料" ], names(kinds: [ "drink_only" ])
    assert_equal 3, names.size
  end

  test "不認得的類型被忽略，不會當成條件或進入 SQL" do
    create(:merchant)

    assert_equal 1, names(kinds: [ "1; DROP TABLE merchants" ]).size, "不認得的類型應被忽略（不篩選）"
    assert_equal 0, MerchantFilter.new({ kinds: [ "evil" ] }).active_count
  end

  test "類型可複選（OR）：同時勾餐＋飲與僅飲料就兩種都顯示" do
    create(:merchant, name: "餐飲", offers_drink: true)
    create(:merchant, name: "只有餐")
    create(:merchant, :drink_only, name: "僅飲料")

    assert_equal %w[僅飲料 餐飲].sort, names(kinds: %w[food_and_drink drink_only]).sort
    assert_equal %w[只有餐 僅飲料 餐飲].sort, names(kinds: %w[food_only food_and_drink drink_only]).sort
  end

  test "類型與其他條件同時成立（AND）" do
    create(:merchant, :drink_only, name: "僅飲料免運", delivery_fee: 0)
    create(:merchant, :drink_only, name: "僅飲料收費", delivery_fee: 60)
    create(:merchant, name: "只有餐免運", delivery_fee: 0)

    assert_equal [ "僅飲料免運" ], names(kinds: [ "drink_only" ], free_delivery: "1")
  end

  test "重複與不認得的類型被忽略，kind?" do
    filter = MerchantFilter.new({ kinds: %w[food_only food_only evil] })

    assert_equal [ "food_only" ], filter.kinds
    assert filter.kind?(:food_only)
    assert_not filter.kind?(:drink_only)
  end

  # --- 19:00 外送 ---

  test "可 19:00 外送：排除明確不可，待確認也顯示" do
    create(:merchant, name: "可以", delivers_at_19: "yes")
    create(:merchant, name: "待確認", delivers_at_19: "unknown")
    create(:merchant, name: "不行", delivers_at_19: "no")

    assert_equal [ "可以", "待確認" ].sort, names(delivers_at_19: "1").sort
  end

  # --- 免外送費 ---

  test "免外送費：明確 0 才算；外送費未知不算" do
    create(:merchant, name: "免運", delivery_fee: 0)
    create(:merchant, name: "有外送費", delivery_fee: 60)
    create(:merchant, name: "外送費未知", delivery_fee: nil)

    assert_equal [ "免運" ], names(free_delivery: "1")
  end

  test "免外送費：滿額免運門檻不高於本場預算也算" do
    create(:merchant, name: "免運", delivery_fee: 0)
    create(:merchant, name: "門檻 1500", delivery_fee: 60, free_delivery_threshold: 1500)
    create(:merchant, name: "門檻 3000", delivery_fee: 60, free_delivery_threshold: 3000)

    assert_equal [ "免運", "門檻 1500" ].sort, names(free_delivery: "1", budget: 1800).sort
    assert_equal [ "免運" ], names(free_delivery: "1", budget: nil)
  end

  # --- 每人 ≤ NT$100 ---

  test "每人 ≤ NT$100：估價沒算出來的店仍顯示" do
    create(:merchant, name: "便宜", price_per_person_min: 80)
    create(:merchant, name: "剛好", price_per_person_min: 100)
    create(:merchant, name: "太貴", price_per_person_min: 120)
    create(:merchant, name: "沒估價")
    create(:merchant, :drink_only, name: "僅飲料")

    assert_equal [ "便宜", "剛好", "沒估價", "僅飲料" ].sort, names(affordable: "1").sort
  end

  test "每人 ≤ NT$100：沒手填時用菜單推算" do
    pricey = create(:merchant, name: "菜單偏貴")
    create(:menu_item, merchant: pricey, price: 150)
    cheap = create(:merchant, name: "菜單便宜")
    create(:menu_item, merchant: cheap, price: 90)

    assert_equal [ "菜單便宜" ], names(affordable: "1")
  end

  # --- 大安區 ---

  test "大安區內 / 可送大安區" do
    create(:merchant, name: "大安區", district: "大安區", delivers_to_daan: "unknown")
    create(:merchant, name: "外區可送", district: "中正區", delivers_to_daan: "yes")
    create(:merchant, name: "外區待確認", district: "中正區", delivers_to_daan: "unknown")
    create(:merchant, name: "外區不送", district: "中正區", delivers_to_daan: "no")

    assert_equal [ "大安區", "外區可送", "外區待確認" ].sort, names(daan: "1").sort
  end

  # --- 菜單 4 個月內 ---

  test "菜單在 4 個月內：至少有一個新鮮項目" do
    fresh = create(:merchant, name: "新鮮")
    create(:menu_item, merchant: fresh)
    stale = create(:merchant, name: "過期")
    create(:menu_item, :stale, merchant: stale)
    unknown = create(:merchant, name: "日期不明")
    create(:menu_item, :date_unknown, merchant: unknown)
    create(:merchant, name: "沒有菜單")

    assert_equal [ "新鮮" ], names(fresh_menu: "1")
  end

  # --- 收藏 / 候選 / 還沒訂過 ---

  test "只看收藏、只看候選、還沒訂過" do
    create(:merchant, name: "收藏", favorited: true)
    create(:merchant, name: "候選", shortlisted: true)
    ordered = create(:merchant, name: "訂過")
    create(:order_record, merchant: ordered)
    create(:merchant, name: "普通")

    assert_equal [ "收藏" ], names(favorited: "1")
    assert_equal [ "候選" ], names(shortlisted: "1")
    assert_equal [ "收藏", "候選", "普通" ].sort, names(never_ordered: "1").sort
  end

  # --- 組合 ---

  test "多個條件同時成立（AND）" do
    create(:merchant, name: "符合", delivery_fee: 0, delivers_at_19: "yes", favorited: true)
    create(:merchant, name: "沒收藏", delivery_fee: 0, delivers_at_19: "yes")
    create(:merchant, name: "不能 19:00", delivery_fee: 0, delivers_at_19: "no", favorited: true)

    assert_equal [ "符合" ], names(free_delivery: "1", delivers_at_19: "1", favorited: "1")
  end

  test "啟用的條件數" do
    filter = MerchantFilter.new({ kinds: [ "food_only" ], free_delivery: "1", favorited: "1", sort: "name" })

    assert_equal 3, filter.active_count
    assert filter.active?
    assert filter.flag?(:free_delivery)
    assert_not filter.flag?(:daan)
  end

  test "旗標只接受 1 / true / on" do
    assert_equal 0, MerchantFilter.new({ favorited: "0" }).active_count
    assert_equal 0, MerchantFilter.new({ favorited: "" }).active_count
    assert_equal 1, MerchantFilter.new({ favorited: "true" }).active_count
    assert_equal 1, MerchantFilter.new({ favorited: "on" }).active_count
  end

  test "接受 ActionController::Parameters" do
    params = ActionController::Parameters.new(favorited: "1", kinds: [ "food_only" ]).permit(:favorited, kinds: [])

    assert_equal 2, MerchantFilter.new(params).active_count
  end

  # --- 排序 ---

  test "依名稱排序" do
    create(:merchant, name: "丙")
    create(:merchant, name: "甲")
    create(:merchant, name: "乙")

    assert_equal [ "乙", "丙", "甲" ].sort, names(sort: "name")
  end

  test "依每人估價低到高，算不出來的排最後" do
    create(:merchant, name: "貴", price_per_person_min: 120)
    create(:merchant, name: "沒估價")
    create(:merchant, name: "便宜", price_per_person_min: 80)
    create(:merchant, name: "中", price_per_person_min: 100)

    assert_equal [ "便宜", "中", "貴", "沒估價" ], names(sort: "price")
  end

  test "不認得的排序退回預設" do
    assert_equal "recent", MerchantFilter.new({ sort: "random" }).sort
  end

  test "每間店只查一次菜單與訂購紀錄（避免 N+1）" do
    3.times do
      merchant = create(:merchant)
      create(:menu_item, merchant: merchant)
      create(:order_record, merchant: merchant)
    end

    queries = []
    callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].match?(/FROM "(menu_items|order_records)"/) }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      MerchantFilter.new.merchants.each { |m| [ m.price_estimate, m.ordered_before?, m.menu_freshness ] }
    end

    assert_operator queries.size, :<=, 2, "預先載入失敗，查詢了 #{queries.size} 次：#{queries.inspect}"
  end
end
