require "test_helper"

class InquiryPairTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 10, 22, 12, 0)
    AppSetting.instance
    @event = create(:event, :with_headcount, held_on: Date.new(2026, 10, 27), headcount: 18)
    @meal_shop = create(:merchant, name: "便當店", delivery_fee: 60, free_delivery_threshold: 1500)
    @meal = create(:menu_item, merchant: @meal_shop, name: "雞腿便當", price: 90, unit: "份")
    @drink_shop = create(:merchant, :drink_only, name: "涼飲店", delivery_fee: 50)
    @drink = create(:menu_item, :drink, merchant: @drink_shop, name: "紅茶", price: 30, unit: "杯")
  end

  def pair(merchant: @meal_shop, partner: @drink_shop, quantities: nil)
    InquiryPair.new(event: @event, merchant: merchant, partner_id: partner&.id&.to_s || "", quantities: quantities)
  end

  def both(meal: 10, drink: 10) = { @meal.id.to_s => meal.to_s, @drink.id.to_s => drink.to_s }

  # --- 搭檔種類與候選 ---

  test "partner_role：飲料店找餐食、餐食店找飲料、餐＋飲都可以" do
    assert_equal :food, pair(merchant: @drink_shop, partner: nil).partner_role
    assert_equal :drink, pair(partner: nil).partner_role
    assert_equal :any, pair(merchant: create(:merchant, :food_and_drink), partner: nil).partner_role
  end

  test "candidates：選飲料 = 賣飲料的店（含餐＋飲），排除自己與明確不外送 19:00 的店" do
    both_shop = create(:merchant, :food_and_drink, name: "餐飲店")
    no_19 = create(:merchant, :drink_only, delivers_at_19: "no")
    food_only = create(:merchant, name: "只有餐")

    result = InquiryPair.candidates(merchant: @meal_shop, role: :drink)

    assert_includes result, @drink_shop
    assert_includes result, both_shop
    assert_not_includes result, no_19
    assert_not_includes result, food_only
    assert_not_includes result, @meal_shop
  end

  test "candidates：選餐食 = 賣餐食的店（含餐＋飲）；any = 全部" do
    both_shop = create(:merchant, :food_and_drink)
    result = InquiryPair.candidates(merchant: @drink_shop, role: :food)

    assert_includes result, @meal_shop
    assert_includes result, both_shop
    assert_not_includes result, @drink_shop
    assert_includes InquiryPair.candidates(merchant: @drink_shop, role: :any), @meal_shop
    assert_includes InquiryPair.candidates(merchant: @meal_shop, role: "bogus"), @drink_shop
  end

  test "candidates 排序：下次訂購 → 收藏 → 最近更新" do
    create(:merchant, :drink_only, name: "普通", updated_at: 1.hour.ago)
    create(:merchant, :drink_only, name: "較新", updated_at: 1.minute.ago)
    create(:merchant, :drink_only, name: "收藏", favorited: true, updated_at: 2.days.ago)
    create(:merchant, :drink_only, name: "候選", shortlisted: true, shortlist_position: 1, updated_at: 3.days.ago)

    names = InquiryPair.candidates(merchant: @meal_shop, role: :drink).map(&:name)

    assert_equal %w[候選 收藏], names.first(2)
    assert_operator names.index("較新"), :<, names.index("普通")
  end

  # --- 搭檔來源 ---

  test "partner_id 指定店家：用它；空字串或 nil 且沒有組：沒有搭檔" do
    assert_equal @drink_shop, pair.partner.merchant
    assert_nil pair(partner: nil).partner
    assert_nil InquiryPair.new(event: @event, merchant: @meal_shop).partner
  end

  test "partner_id 是自己、不存在、亂填：當作沒有搭檔，不報錯" do
    [ @meal_shop.id.to_s, "999999", "abc" ].each do |id|
      assert_nil InquiryPair.new(event: @event, merchant: @meal_shop, partner_id: id).partner, id
    end
  end

  test "沒指定 partner_id：用主店詢問單所在組的另一家" do
    pair(quantities: both).save

    reopened = InquiryPair.new(event: @event, merchant: @meal_shop)

    assert_equal @drink_shop, reopened.partner.merchant
    assert_equal 10, reopened.main.quantity_for(@meal)
    assert_equal 10, reopened.partner.quantity_for(@drink)
  end

  test "partner_id 空字串：明確移除，即使已經有組" do
    pair(quantities: both).save

    assert_nil InquiryPair.new(event: @event, merchant: @meal_shop, partner_id: "").partner
  end

  test "剛選的搭檔沒有品項在請求裡：用它已存的詢問單當預設數量" do
    pair(quantities: both(meal: 4, drink: 6)).save

    p = pair(quantities: { @meal.id.to_s => "7" }) # 請求只有主店

    assert_equal 7, p.main.quantity_for(@meal)
    assert_equal 6, p.partner.quantity_for(@drink)
  end

  test "請求有搭檔品項（即使是 0）就用請求的" do
    pair(quantities: both(meal: 4, drink: 6)).save

    p = pair(quantities: both(meal: 4, drink: 0))

    assert_equal 0, p.partner.quantity_for(@drink)
  end

  # --- 金額 ---

  test "兩家合計：小計相加、外送費相加、預計總額" do
    p = pair(quantities: both(meal: 10, drink: 20)) # 900 + 600 = 1500；60 + 50

    assert_equal 1500, p.combined.subtotal
    assert_equal 110, p.combined.delivery_fee
    assert_equal 1610, p.combined.total
  end

  test "滿額免運只看各自那家的小計" do
    p = pair(quantities: both(meal: 18, drink: 1)) # 便當 1620 ≥ 1500 免運；飲料 30 + 50

    assert_equal 0, p.main.pricing.delivery_fee
    assert_equal 50, p.combined.delivery_fee
    assert_equal 1700, p.combined.total
  end

  test "任一家外送費未知：外送費與總額待確認，小計照算" do
    @drink_shop.update!(delivery_fee: nil)

    p = pair(quantities: both)

    assert_equal 1200, p.combined.subtotal
    assert_nil p.combined.delivery_fee
    assert_nil p.combined.total
  end

  test "沒選品項的那家不計金額，也不多算外送費" do
    p = pair(quantities: both(meal: 10, drink: 0))

    assert_equal [ @meal_shop ], p.selected_forms.map(&:merchant)
    assert_equal 900, p.combined.subtotal
    assert_equal 60, p.combined.delivery_fee
  end

  # --- 預算 ---

  test "預算：只算目前這兩家的試算，不含本場其他店家或這兩家已存的詢問單" do
    pair(quantities: both(meal: 10, drink: 10)).save
    other = create(:merchant)
    create(:order_inquiry, event: @event, merchant: other, subtotal: 5000, delivery_fee: 0, total: 5000)

    p = pair(quantities: both(meal: 5, drink: 5)) # 試算：450+60 + 150+50 = 710

    assert_equal 710, p.budget.known_total
    assert_equal 1800, p.budget.total_budget
  end

  test "預算：沒選的那家不計（即使它有已存的詢問單）" do
    pair(quantities: both(meal: 10, drink: 10)).save

    p = pair(quantities: both(meal: 10, drink: 0))

    assert_equal 960, p.budget.known_total
  end

  test "預算：超出時狀態是 over" do
    assert_equal :over, pair(quantities: both(meal: 18, drink: 18)).budget.status # 1620 + 540 + 50
  end

  # --- 驗證 ---

  test "兩家都沒選：只有「請至少選一項餐點」，不算要顯示的錯誤" do
    p = pair(quantities: both(meal: 0, drink: 0))

    assert_not p.valid?
    assert_equal [], p.visible_errors
    assert_not p.any_lines?
  end

  test "只有一家有選就可以（另一家略過）" do
    assert pair(quantities: both(meal: 10, drink: 0)).valid?
    assert pair(quantities: both(meal: 0, drink: 10)).valid?
  end

  test "某家數量不合法：整個擋下，錯誤帶店名" do
    p = pair(quantities: both(meal: 10, drink: "abc"))

    assert_not p.valid?
    assert_match(/涼飲店：「紅茶」的數量必須是 0 到 99/, p.visible_errors.join)
  end

  test "單店時錯誤不帶店名" do
    p = pair(partner: nil, quantities: { @meal.id.to_s => "abc" })

    p.valid?

    assert_match(/\A「雞腿便當」/, p.visible_errors.first)
  end

  test "沒有活動 / 沒有人數：blocked" do
    no_headcount = create(:event, held_on: Date.new(2026, 11, 24))
    p = InquiryPair.new(event: no_headcount, merchant: @meal_shop, partner_id: "")

    assert p.blocked?
    assert_equal :no_headcount, p.blocked_reason
  end

  # --- 儲存與分組 ---

  test "兩家都有品項：各存一張詢問單並綁成一組，各自金額與訊息" do
    result = nil
    assert_difference [ "OrderInquiry.count" ], 2 do
      assert_difference "OrderGroup.count", 1 do
        result = pair(quantities: both(meal: 10, drink: 20)).save
      end
    end

    meal_inquiry, drink_inquiry = result
    assert_equal meal_inquiry.order_group, drink_inquiry.order_group
    assert_equal 960, meal_inquiry.total
    assert_equal 650, drink_inquiry.total
    assert_includes meal_inquiry.message_text, "- 雞腿便當 × 10 份"
    assert_includes drink_inquiry.message_text, "- 紅茶 × 20 杯"
    assert_not_includes meal_inquiry.message_text, "紅茶"
    assert meal_inquiry.draft? && drink_inquiry.draft?
  end

  test "channel 只標在被按的那家，另一家維持草稿" do
    meal_inquiry, drink_inquiry = pair(quantities: both).save(channel: "line", contact_merchant_id: @drink_shop.id)

    assert drink_inquiry.sent?
    assert drink_inquiry.via_line?
    assert meal_inquiry.draft?
    assert_nil meal_inquiry.contacted_via
  end

  test "沒指定 contact_merchant_id：channel 標在主店" do
    meal_inquiry, drink_inquiry = pair(quantities: both).save(channel: "phone")

    assert meal_inquiry.sent?
    assert drink_inquiry.draft?
  end

  test "被按聯絡按鈕的那家沒選品項：不存、回報錯誤" do
    p = pair(quantities: both(meal: 10, drink: 0))

    assert_no_difference "OrderInquiry.count" do
      assert_not p.save(channel: "line", contact_merchant_id: @drink_shop.id)
    end
    assert_includes p.errors.full_messages, "這間店還沒選餐點，不能標為已詢問"
  end

  test "只有一家有品項：只存那一家，不建立組" do
    result = nil
    assert_no_difference "OrderGroup.count" do
      assert_difference "OrderInquiry.count", 1 do
        result = pair(quantities: both(meal: 10, drink: 0)).save
      end
    end
    assert_nil result.first.order_group
  end

  test "再存一次：覆蓋兩張、沿用同一組" do
    first = pair(quantities: both(meal: 10, drink: 10)).save

    assert_no_difference [ "OrderInquiry.count", "OrderGroup.count" ] do
      @again = pair(quantities: both(meal: 3, drink: 4)).save
    end
    assert_equal first.map(&:id), @again.map(&:id)
    assert_equal [ 3 ], @again.first.items.reload.map(&:quantity)
    assert_equal [ 4 ], @again.last.items.reload.map(&:quantity)
  end

  test "換搭檔：舊搭檔的詢問單保留（狀態不變）但離組，舊組刪除，新搭檔綁成新組" do
    meal_inquiry, old_drink = pair(quantities: both).save(channel: "line", contact_merchant_id: @drink_shop.id)
    new_shop = create(:merchant, :drink_only, name: "新飲料店", delivery_fee: 0)
    new_drink = create(:menu_item, :drink, merchant: new_shop, name: "綠茶", price: 25)
    old_group = meal_inquiry.order_group

    result = InquiryPair.new(event: @event, merchant: @meal_shop, partner_id: new_shop.id.to_s,
                             quantities: { @meal.id.to_s => "5", new_drink.id.to_s => "5" }).save

    assert_equal 3, OrderInquiry.count
    assert_nil old_drink.reload.order_group_id
    assert old_drink.sent?
    assert_not OrderGroup.exists?(old_group.id)
    assert_equal result.first.order_group, result.last.order_group
    assert_equal new_shop, result.last.merchant
    assert_equal 1, OrderGroup.count
  end

  test "移除搭檔後只存主店：舊組不動，下次沒指定時仍帶出舊搭檔" do
    pair(quantities: both).save

    InquiryPair.new(event: @event, merchant: @meal_shop, partner_id: "", quantities: { @meal.id.to_s => "2" }).save

    assert_equal 1, OrderGroup.count
    assert_equal @drink_shop, InquiryPair.new(event: @event, merchant: @meal_shop).partner.merchant
  end

  test "已確認訂購的那家不能改，整個不存" do
    meal_inquiry, = pair(quantities: both).save
    meal_inquiry.confirm!

    p = pair(quantities: both(meal: 1, drink: 1))

    assert_not p.save
    assert_match(/便當店：.*已確認訂購/, p.errors.full_messages.join)
    assert_equal 10, meal_inquiry.reload.items.first.quantity
  end

  test "任何一家驗證失敗：什麼都不寫入" do
    assert_no_difference [ "OrderInquiry.count", "OrderInquiryItem.count", "OrderGroup.count" ] do
      assert_not pair(quantities: both(meal: 10, drink: "abc")).save
    end
  end

  test "餐＋飲的店也能當搭檔或主店" do
    both_shop = create(:merchant, :food_and_drink, name: "餐飲店", delivery_fee: 0)
    item = create(:menu_item, merchant: both_shop, name: "套餐", price: 100)

    result = InquiryPair.new(event: @event, merchant: both_shop, partner_id: @drink_shop.id.to_s,
                             quantities: { item.id.to_s => "5", @drink.id.to_s => "5" }).save

    assert_equal 2, result.size
    assert_equal result.first.order_group, result.last.order_group
  end
end
