require "test_helper"

class MerchantTest < ActiveSupport::TestCase
  test "預設值：賣餐食、不賣飲料、19:00 外送與送大安區都是待確認" do
    merchant = create(:merchant)

    assert merchant.offers_food
    assert_not merchant.offers_drink
    assert merchant.delivers_at_19_unknown?
    assert merchant.delivers_to_daan_unknown?
    assert_nil merchant.delivery_fee, "外送費未知要存 NULL，不是 0"
  end

  test "名稱必填" do
    assert_not build(:merchant, name: "").valid?
  end

  test "餐食與飲料至少賣一種" do
    merchant = build(:merchant, offers_food: false, offers_drink: false)

    assert_not merchant.valid?
    assert_includes merchant.errors[:base], "至少要販售餐食或飲料其中一種"
  end

  test "資料庫層也擋掉兩者都不賣（即使跳過驗證）" do
    merchant = build(:merchant, offers_food: false, offers_drink: false)

    assert_raises(ActiveRecord::StatementInvalid) { merchant.save!(validate: false) }
  end

  test "只賣飲料的店可以存在" do
    merchant = create(:merchant, :drink_only)

    assert merchant.drink_only?
    assert_equal :drink_only, merchant.kind
  end

  test "kind 區分餐+飲、只有餐、只有飲料" do
    assert_equal :food_and_drink, build(:merchant, :food_and_drink).kind
    assert_equal :food_only, build(:merchant).kind
    assert_equal :drink_only, build(:merchant, :drink_only).kind
  end

  test "enum 只接受 yes / no / unknown" do
    assert_not build(:merchant, delivers_at_19: "maybe").valid?
  end

  test "金額不可為負" do
    assert_not build(:merchant, delivery_fee: -1).valid?
    assert build(:merchant, delivery_fee: 0).valid?
  end

  test "每人最高估價不可低於最低估價" do
    assert_not build(:merchant, price_per_person_min: 100, price_per_person_max: 80).valid?
    assert build(:merchant, price_per_person_min: 80, price_per_person_max: 100).valid?
  end

  test "座標可為空，但有值時要在合理範圍" do
    assert build(:merchant, lat: nil, lng: nil).valid?
    assert_not build(:merchant, lat: 91).valid?
    assert_not build(:merchant, lng: 181).valid?
  end

  # --- 篩選 scopes ---

  test "餐飲類型 scopes" do
    food = create(:merchant)
    both = create(:merchant, :food_and_drink)
    drink = create(:merchant, :drink_only)

    assert_equal [ food ], Merchant.food_only.to_a
    assert_equal [ both ], Merchant.food_and_drink.to_a
    assert_equal [ drink ], Merchant.drink_only.to_a
  end

  test "可 19:00 外送：排除明確不可，待確認也顯示" do
    yes = create(:merchant, delivers_at_19: "yes")
    unknown = create(:merchant, delivers_at_19: "unknown")
    create(:merchant, delivers_at_19: "no")

    assert_equal [ yes, unknown ].sort_by(&:id), Merchant.possibly_delivers_at_19.sort_by(&:id)
  end

  test "免外送費：外送費為 0，或滿額免運且門檻不高於預算" do
    free = create(:merchant, delivery_fee: 0)
    threshold_ok = create(:merchant, delivery_fee: 60, free_delivery_threshold: 1500)
    create(:merchant, delivery_fee: 60, free_delivery_threshold: 3000)
    create(:merchant, delivery_fee: nil)

    assert_equal [ free ], Merchant.free_delivery.to_a
    assert_equal [ free, threshold_ok ].sort_by(&:id), Merchant.free_delivery(1800).sort_by(&:id)
  end

  test "每人估價不超過上限" do
    cheap = create(:merchant, price_per_person_min: 80)
    create(:merchant, price_per_person_min: 120)
    create(:merchant, price_per_person_min: nil)

    assert_equal [ cheap ], Merchant.price_per_person_within(100).to_a
  end

  test "曾訂購 / 沒訂過" do
    ordered = create(:merchant)
    never = create(:merchant)
    create(:order_record, merchant: ordered)

    assert_equal [ ordered ], Merchant.ordered_before.to_a
    assert_equal [ never ], Merchant.never_ordered.to_a
    assert ordered.ordered_before?
    assert_not never.ordered_before?
  end

  test "候選名單依 shortlist_position 排序" do
    second = create(:merchant, shortlisted: true, shortlist_position: 2)
    first = create(:merchant, shortlisted: true, shortlist_position: 1)
    create(:merchant, shortlisted: false)

    assert_equal [ first, second ], Merchant.shortlisted.to_a
  end

  # --- 聯絡管道 ---

  test "聯絡管道順序固定：LINE → Instagram → Messenger → 電話" do
    merchant = create(:merchant, :with_contacts)

    assert_equal(
      [
        [ :line, "https://line.me/R/ti/p/@rubyjam" ],
        [ :instagram, "https://ig.me/m/rubyjam.lunch" ],
        [ :messenger, "https://m.me/rubyjam.page" ],
        [ :phone, "tel:0223456789" ]
      ],
      merchant.contact_links
    )
  end

  test "只列出有資料的管道，沒有任何管道時為空" do
    assert_equal [ [ :phone, "tel:0223456789" ] ], create(:merchant, phone: "02-2345-6789").contact_links
    assert_empty create(:merchant).contact_links
  end

  test "個人 LINE ID 用 ~ 前綴" do
    assert_equal [ [ :line, "https://line.me/R/ti/p/~abc123" ] ], create(:merchant, line_id: "~abc123").contact_links
  end

  test "LINE ID 必須有 @ 或 ~ 前綴" do
    assert_not build(:merchant, line_id: "rubyjam").valid?
  end

  test "Instagram 帳號會去掉開頭的 @，且擋掉奇怪字元" do
    assert_equal "rubyjam", create(:merchant, instagram: " @rubyjam ").instagram
    assert_not build(:merchant, instagram: "ruby/jam?x=1").valid?
  end

  test "電話只能包含數字與常見符號，擋掉 javascript: 之類的字串" do
    assert_not build(:merchant, phone: "javascript:alert(1)").valid?
  end

  # --- 距離 ---

  test "沒有座標時沒有距離" do
    assert_nil build(:merchant).distance_km
  end

  test "與 PicCollage 同座標時距離為 0" do
    merchant = build(:merchant, lat: Merchant::PICCOLLAGE_LAT, lng: Merchant::PICCOLLAGE_LNG)

    assert_equal 0.0, merchant.distance_km
  end

  test "距離是到 PicCollage 的直線公里數" do
    # 往北約 0.01 度 ≈ 1.11 公里
    merchant = build(:merchant, lat: Merchant::PICCOLLAGE_LAT + 0.01, lng: Merchant::PICCOLLAGE_LNG)

    assert_in_delta 1.11, merchant.distance_km, 0.02
  end

  # --- 刪除 ---

  test "有詢問單的店家不可刪除" do
    inquiry = create(:order_inquiry)

    assert_not inquiry.merchant.destroy
    assert inquiry.merchant.errors.any?
  end

  test "有訂購紀錄的店家不可刪除" do
    record = create(:order_record)

    assert_not record.merchant.destroy
  end

  test "刪除店家會一併刪除菜單與來源" do
    merchant = create(:merchant)
    create(:menu_item, merchant: merchant)
    create(:merchant_source, merchant: merchant)

    assert_difference [ "MenuItem.count", "MerchantSource.count" ], -1 do
      merchant.destroy!
    end
  end

  # --- 每人估價（手填優先，沒填用新鮮菜單推算） ---

  test "有手填估價就用手填" do
    merchant = create(:merchant, price_per_person_min: 80, price_per_person_max: 100)
    create(:menu_item, merchant: merchant, price: 200)

    estimate = merchant.reload.price_estimate

    assert_equal [ 80, 100, :manual ], [ estimate.min, estimate.max, estimate.source ]
  end

  test "只填最低估價時最高等於最低" do
    estimate = build(:merchant, price_per_person_min: 90).price_estimate

    assert_equal [ 90, 90 ], [ estimate.min, estimate.max ]
  end

  test "沒手填：最便宜餐食 + 最便宜飲料" do
    merchant = create(:merchant, :food_and_drink)
    create(:menu_item, merchant: merchant, price: 95)
    create(:menu_item, merchant: merchant, price: 120)
    create(:menu_item, :drink, merchant: merchant, price: 35)
    create(:menu_item, :drink, merchant: merchant, price: 50)

    estimate = merchant.reload.price_estimate

    assert_equal [ 130, :menu ], [ estimate.min, estimate.source ]
  end

  test "只有餐的店不把飲料算進估價" do
    merchant = create(:merchant)
    create(:menu_item, merchant: merchant, price: 90)
    create(:menu_item, :drink, merchant: merchant, price: 30)

    assert_equal 90, merchant.reload.price_estimate.min
  end

  test "過期或日期不明的菜單不參與推算，算不出來就是 nil" do
    merchant = create(:merchant)
    create(:menu_item, :stale, merchant: merchant)
    create(:menu_item, :date_unknown, merchant: merchant)

    assert_nil merchant.reload.price_estimate
  end

  test "只賣飲料的店沒有每人估價，改看最便宜的整箱 / 整桶單價" do
    merchant = create(:merchant, :drink_only)
    create(:menu_item, :drink, merchant: merchant, name: "冬瓜茶（一桶）", price: 280, unit: "桶", servings: 20)
    create(:menu_item, :drink, merchant: merchant, name: "紅茶（一箱）", price: 360, unit: "箱", servings: 24)
    merchant.reload

    assert_nil merchant.price_estimate
    assert_equal 280, merchant.bulk_drink_item.price
  end

  test "非僅飲料的店沒有 bulk_drink_item" do
    assert_nil create(:merchant, :food_and_drink).bulk_drink_item
  end

  # --- 確認菜單仍有效 ---

  test "確認菜單：所有項目日期改為今天並記錄驗證時間" do
    merchant = create(:merchant)
    stale = create(:menu_item, :stale, merchant: merchant)
    unknown = create(:menu_item, :date_unknown, merchant: merchant)

    merchant.verify_menu!

    assert_equal Date.current, stale.reload.menu_date
    assert_equal Date.current, unknown.reload.menu_date
    assert_not_nil merchant.reload.last_verified_at
    assert merchant.menu_items.all?(&:orderable?)
  end

  # --- 重複店家提醒 ---

  test "電話只比數字，格式不同也視為重複" do
    existing = create(:merchant, phone: "02-2345-6789")
    candidate = build(:merchant, phone: "(02) 2345 6789")

    assert_equal [ existing ], candidate.possible_duplicates
  end

  test "Instagram 帳號相同（不分大小寫）視為重複" do
    existing = create(:merchant, instagram: "RubyJam")

    assert_equal [ existing ], build(:merchant, instagram: "rubyjam").possible_duplicates
  end

  test "沒有電話與 Instagram 時沒有重複，且不會和自己比" do
    create(:merchant)
    merchant = create(:merchant, phone: "02-1111-2222")

    assert_empty build(:merchant).possible_duplicates
    assert_empty merchant.possible_duplicates
  end

  # --- 巢狀屬性 ---

  test "表單送出的菜單列：完全空白的列被忽略" do
    merchant = Merchant.create!(
      name: "巢狀測試",
      menu_items_attributes: {
        "0" => { name: "雞腿飯", category: "food", price: "90", menu_date: Date.current.to_s },
        "1" => { name: "", category: "food", price: "", menu_date: "" }
      }
    )

    assert_equal 1, merchant.menu_items.count
  end

  test "只填品名沒填價格會驗證失敗" do
    merchant = Merchant.new(name: "巢狀測試", menu_items_attributes: { "0" => { name: "雞腿飯", category: "food", price: "" } })

    assert_not merchant.valid?
  end

  test "來源網址空白的列被忽略，非 https 的網址會被擋" do
    assert_equal 0, Merchant.create!(name: "A", sources_attributes: { "0" => { platform: "manual", url: "" } }).sources.count

    merchant = Merchant.new(name: "B", sources_attributes: { "0" => { platform: "manual", url: "http://example.com" } })
    assert_not merchant.valid?
  end

  test "Threads 帳號會去掉開頭的 @" do
    assert_equal "rubyjam", create(:merchant, threads: "@rubyjam").threads
    assert_not build(:merchant, threads: "a/b").valid?
  end

  test "菜單變動時店家的 updated_at 會更新" do
    merchant = create(:merchant)
    merchant.update_column(:updated_at, 1.day.ago)

    create(:menu_item, merchant: merchant)

    assert_in_delta Time.current, merchant.reload.updated_at, 5
  end

  # --- 收藏與下次候選 ---

  test "收藏與取消收藏" do
    merchant = create(:merchant)

    merchant.favorite!
    assert merchant.reload.favorited

    merchant.favorite!(false)
    assert_not merchant.reload.favorited
  end

  test "收藏與候選不算更新店家：不改 updated_at，列表順序不會跳動" do
    merchant = create(:merchant)
    merchant.update_column(:updated_at, 5.days.ago)
    before = merchant.reload.updated_at

    merchant.favorite!
    merchant.add_to_shortlist!
    merchant.remove_from_shortlist!

    assert_equal before, merchant.reload.updated_at
  end

  test "加入候選：排在候選名單最後" do
    first = create(:merchant)
    second = create(:merchant)
    third = create(:merchant)

    [ first, second, third ].each(&:add_to_shortlist!)

    assert_equal [ 1, 2, 3 ], [ first, second, third ].map { |m| m.reload.shortlist_position }
    assert_equal [ first, second, third ], Merchant.shortlisted.to_a
  end

  test "已在候選時再加入：什麼都不做，位置不變" do
    merchant = create(:merchant)
    merchant.add_to_shortlist!
    create(:merchant).add_to_shortlist!

    merchant.add_to_shortlist!

    assert_equal 1, merchant.reload.shortlist_position
  end

  test "移出候選：清掉位置但保留備註" do
    merchant = create(:merchant, shortlist_note: "上次反應不錯")
    merchant.add_to_shortlist!

    merchant.remove_from_shortlist!

    assert_not merchant.reload.shortlisted
    assert_nil merchant.shortlist_position
    assert_equal "上次反應不錯", merchant.shortlist_note
  end

  test "移出後再加入：位置接在目前最後一個後面，不會撞號" do
    a = create(:merchant)
    b = create(:merchant)
    c = create(:merchant)
    [ a, b, c ].each(&:add_to_shortlist!)

    b.remove_from_shortlist!
    b.add_to_shortlist!

    assert_equal [ a, c, b ], Merchant.shortlisted.to_a
    assert_equal [ 1, 3, 4 ], Merchant.shortlisted.map(&:shortlist_position)
  end

  test "收藏與候選互相獨立" do
    merchant = create(:merchant)

    merchant.favorite!
    assert_not merchant.reload.shortlisted

    merchant.add_to_shortlist!
    merchant.favorite!(false)
    assert merchant.reload.shortlisted
  end

  # --- 瀏覽歷史 ---

  test "記錄瀏覽：只更新最後瀏覽時間，不改 updated_at" do
    merchant = create(:merchant)
    merchant.update_column(:updated_at, 4.days.ago)
    before = merchant.reload.updated_at

    merchant.record_view!

    assert_in_delta Time.current, merchant.reload.last_viewed_at, 5
    assert_equal before, merchant.updated_at
  end

  test "瀏覽歷史：最近看的在前，沒看過的不列入" do
    old = create(:merchant, name: "舊")
    recent = create(:merchant, name: "新")
    create(:merchant, name: "沒看過")
    old.record_view!(at: 3.days.ago)
    recent.record_view!(at: 1.hour.ago)

    assert_equal [ recent, old ], Merchant.recently_viewed.to_a
  end

  test "瀏覽歷史最多 20 間，保留最近的" do
    merchants = Array.new(23) { |i| create(:merchant).tap { |m| m.record_view!(at: (23 - i).hours.ago) } }

    history = Merchant.recently_viewed.to_a

    assert_equal Merchant::HISTORY_LIMIT, history.size
    assert_equal merchants.last, history.first
    assert_not_includes history, merchants.first
  end

  test "再看一次同一間店：只更新時間，歷史裡仍只有一筆" do
    merchant = create(:merchant)
    merchant.record_view!(at: 2.days.ago)

    merchant.record_view!

    assert_equal [ merchant ], Merchant.recently_viewed.to_a
    assert_in_delta Time.current, merchant.reload.last_viewed_at, 5
  end

  # --- 候選名單：排序與備註 ---

  def shortlist_of(*merchants)
    merchants.each(&:add_to_shortlist!)
    Merchant.shortlisted.map(&:name)
  end

  test "move_in_shortlist!：往前 / 往後一位，和相鄰的交換" do
    a, b, c = %w[甲 乙 丙].map { |name| create(:merchant, name: name) }
    shortlist_of(a, b, c)

    assert b.reload.move_in_shortlist!(:up)
    assert_equal %w[乙 甲 丙], Merchant.shortlisted.map(&:name)
    assert b.reload.move_in_shortlist!("down")
    assert_equal %w[甲 乙 丙], Merchant.shortlisted.map(&:name)
    assert a.reload.move_in_shortlist!(:down)
    assert_equal %w[乙 甲 丙], Merchant.shortlisted.map(&:name)
  end

  test "move_in_shortlist!：已經在最前 / 最後就不動，回傳 false" do
    a, b = %w[甲 乙].map { |name| create(:merchant, name: name) }
    shortlist_of(a, b)

    assert_not a.reload.move_in_shortlist!(:up)
    assert_not b.reload.move_in_shortlist!(:down)
    assert_equal %w[甲 乙], Merchant.shortlisted.map(&:name)
  end

  test "move_in_shortlist!：不在候選、方向不認得都不動" do
    a, b = %w[甲 乙].map { |name| create(:merchant, name: name) }
    shortlist_of(a, b)
    outsider = create(:merchant)

    assert_not outsider.move_in_shortlist!(:up)
    assert_not b.reload.move_in_shortlist!(:sideways)
    assert_not b.reload.move_in_shortlist!(nil)
    assert_equal %w[甲 乙], Merchant.shortlisted.map(&:name)
  end

  test "move_in_shortlist!：位置有重複或空位時先整理成 1..n 再移動" do
    a, b, c = %w[甲 乙 丙].map { |name| create(:merchant, name: name) }
    shortlist_of(a, b, c)
    a.update_columns(shortlist_position: 5)
    b.update_columns(shortlist_position: 5)
    c.update_columns(shortlist_position: 9)

    assert c.reload.move_in_shortlist!(:up)

    assert_equal [ 1, 2, 3 ], Merchant.shortlisted.map(&:shortlist_position)
    assert_equal %w[甲 丙 乙], Merchant.shortlisted.map(&:name)
  end

  test "move_in_shortlist! 不改 updated_at（列表依最近更新排序，排序不該讓它跳動）" do
    a, b = %w[甲 乙].map { |name| create(:merchant, name: name) }
    shortlist_of(a, b)
    before = b.reload.updated_at

    travel(1.hour) { b.move_in_shortlist!(:up) }

    assert_equal before, b.reload.updated_at
  end

  test "update_shortlist_note!：存備註、空白存成 nil、超過上限不存" do
    merchant = create(:merchant)

    assert merchant.update_shortlist_note!("  上次太鹹\n要提前兩天訂  ")
    assert_equal "上次太鹹\n要提前兩天訂", merchant.reload.shortlist_note

    assert merchant.update_shortlist_note!("   ")
    assert_nil merchant.reload.shortlist_note

    merchant.update_shortlist_note!("保留")
    assert_not merchant.update_shortlist_note!("字" * (Merchant::SHORTLIST_NOTE_LIMIT + 1))
    assert_equal "保留", merchant.reload.shortlist_note
    assert merchant.update_shortlist_note!("字" * Merchant::SHORTLIST_NOTE_LIMIT)
  end

  test "備註在移出候選後保留，再加回來還在" do
    merchant = create(:merchant)
    merchant.add_to_shortlist!
    merchant.update_shortlist_note!("備註")

    merchant.remove_from_shortlist!
    merchant.add_to_shortlist!

    assert_equal "備註", merchant.reload.shortlist_note
  end

  test "recently_ordered_on：最近一筆訂購在 45 天內才有，剛好 45 天也算" do
    travel_to Date.new(2026, 10, 27) do
      merchant = create(:merchant)
      assert_nil merchant.recently_ordered_on

      create(:order_record, merchant: merchant, ordered_on: Date.new(2026, 8, 12)) # 76 天前
      assert_nil merchant.reload.recently_ordered_on

      create(:order_record, merchant: merchant, ordered_on: Date.new(2026, 9, 12)) # 剛好 45 天
      assert_equal Date.new(2026, 9, 12), merchant.reload.recently_ordered_on

      create(:order_record, merchant: merchant, ordered_on: Date.new(2026, 10, 6))
      assert_equal Date.new(2026, 10, 6), merchant.reload.recently_ordered_on
      assert_equal Date.new(2026, 10, 6), merchant.last_ordered_on
    end
  end

  test "recently_ordered_on：46 天前不算；日期不明的紀錄被忽略" do
    travel_to Date.new(2026, 10, 27) do
      merchant = create(:merchant)
      create(:order_record, merchant: merchant, ordered_on: Date.new(2026, 9, 11)) # 46 天
      create(:order_record, merchant: merchant, ordered_on: nil)

      assert_nil merchant.reload.recently_ordered_on
      assert_equal Date.new(2026, 9, 11), merchant.last_ordered_on
    end
  end

  test "活動日在未來的紀錄（詢問單確認訂購）也算剛訂過" do
    travel_to Date.new(2026, 10, 27) do
      merchant = create(:merchant)
      create(:order_record, merchant: merchant, source: "inquiry", ordered_on: Date.new(2026, 11, 3))

      assert_equal Date.new(2026, 11, 3), merchant.reload.recently_ordered_on
    end
  end
end
