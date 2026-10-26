require "test_helper"

# 「已詢問」頁的訂購按鈕：記錄這家有訂購，更新店家的「曾訂購」
class InquiryConfirmationsTest < ActionDispatch::IntegrationTest
  setup do
    @event = create(:event, held_on: Date.new(2026, 10, 27))
    @merchant = create(:merchant, name: "阿嬤便當")
    @inquiry = create(:order_inquiry, event: @event, merchant: @merchant, status: "sent", contacted_via: "line", sent_at: Time.current, headcount_at_creation: 18, total: 1620, subtotal: 1620)
  end

  test "已詢問頁有「訂購」欄位與按鈕（尚未訂購的）" do
    get inquiries_path

    assert_select "thead th", text: "訂購"
    assert_select "tbody form[action=?]", inquiry_confirmation_path(@inquiry) do
      assert_select "button", text: "訂購"
    end
    assert_select "tbody form[data-turbo-confirm]"
  end

  test "按訂購：詢問單變已訂購，建立訂購紀錄，店家出現曾訂購" do
    assert_not @merchant.reload.ordered_before?

    assert_difference "OrderRecord.count", 1 do
      post inquiry_confirmation_path(@inquiry)
    end

    assert_redirected_to inquiries_path
    assert_response :see_other
    assert @inquiry.reload.confirmed?
    assert @merchant.reload.ordered_before?
    record = @inquiry.order_record
    assert_equal [ @merchant, @event, 18, 1620, "inquiry" ], [ record.merchant, record.event, record.headcount, record.total, record.source ]
    assert_equal @event.held_on, record.ordered_on
  end

  test "訂購後：首頁卡片圓點是曾訂購、側欄與已訂購頁都有這筆" do
    post inquiry_confirmation_path(@inquiry)

    get root_path
    assert_select "article", text: /阿嬤便當/ do
      assert_select "span", text: "曾訂購"
    end
    assert_select "aside a", text: /已訂購\s*1/
    get orders_path
    assert_select "tbody td a", text: "阿嬤便當"
  end

  test "已訂購的列：顯示已訂購標籤與取消訂購，不再有訂購按鈕" do
    @inquiry.confirm!

    get inquiries_path

    assert_select "tbody span.bg-primary", text: "已訂購"
    assert_select "tbody form[action=?] button", inquiry_confirmation_path(@inquiry), text: "取消訂購"
    assert_select "tbody form button", text: "訂購", count: 0
  end

  test "取消訂購：退回已詢問，刪掉自動產生的紀錄，曾訂購圓點回到沒訂過" do
    @inquiry.confirm!

    assert_difference "OrderRecord.count", -1 do
      delete inquiry_confirmation_path(@inquiry)
    end

    assert_redirected_to inquiries_path
    assert @inquiry.reload.sent?
    assert_not @merchant.reload.ordered_before?
  end

  test "取消訂購不會動到手動補登的紀錄" do
    create(:order_record, merchant: @merchant, source: "manual", ordered_on: Date.new(2026, 9, 1))
    @inquiry.confirm!

    delete inquiry_confirmation_path(@inquiry)

    assert @merchant.reload.ordered_before?
    assert_equal 1, @merchant.order_records.count
  end

  test "重複按訂購或取消：結果一致，不會多一筆紀錄（冪等）" do
    post inquiry_confirmation_path(@inquiry)
    assert_no_difference "OrderRecord.count" do
      post inquiry_confirmation_path(@inquiry)
    end

    delete inquiry_confirmation_path(@inquiry)
    assert_no_difference "OrderRecord.count" do
      delete inquiry_confirmation_path(@inquiry)
    end
    assert_response :see_other
  end

  test "草稿也能記錄訂購（例如直接打電話訂）" do
    draft = create(:order_inquiry, event: @event, merchant: create(:merchant), status: "draft")

    post inquiry_confirmation_path(draft)

    assert draft.reload.confirmed?
  end

  test "外送費未知（預計金額 nil）也能記錄，金額留空" do
    unknown = create(:order_inquiry, :fee_unknown, event: @event, merchant: create(:merchant))

    post inquiry_confirmation_path(unknown)

    assert unknown.reload.confirmed?
    assert_nil unknown.order_record.total
  end

  test "配對的兩家：按其中一家的訂購，另一家也記錄為已訂購，兩家都變曾訂購" do
    group = create(:order_group, event: @event)
    drink_shop = create(:merchant, :drink_only, name: "涼飲店")
    drink = create(:order_inquiry, event: @event, merchant: drink_shop, order_group: group)
    @inquiry.update!(order_group: group)

    assert_difference "OrderRecord.count", 2 do
      post inquiry_confirmation_path(@inquiry)
    end

    assert @inquiry.reload.confirmed?
    assert drink.reload.confirmed?
    assert @merchant.reload.ordered_before?
    assert drink_shop.reload.ordered_before?
    assert_equal "已記錄「阿嬤便當」、「涼飲店」為已訂購", flash[:notice]
  end

  test "配對的另一家已經訂購過：不會多一筆紀錄" do
    group = create(:order_group, event: @event)
    drink = create(:order_inquiry, event: @event, merchant: create(:merchant, :drink_only), order_group: group)
    drink.confirm!
    @inquiry.update!(order_group: group)

    assert_difference "OrderRecord.count", 1 do
      post inquiry_confirmation_path(@inquiry)
    end
  end

  test "配對的兩家：取消其中一家，另一家也取消" do
    group = create(:order_group, event: @event)
    drink_shop = create(:merchant, :drink_only)
    drink = create(:order_inquiry, event: @event, merchant: drink_shop, order_group: group, status: "sent", sent_at: Time.current)
    @inquiry.update!(order_group: group)
    post inquiry_confirmation_path(@inquiry)

    assert_difference "OrderRecord.count", -2 do
      delete inquiry_confirmation_path(drink)
    end

    assert @inquiry.reload.sent?
    assert drink.reload.sent?
    assert_not @merchant.reload.ordered_before?
    assert_not drink_shop.reload.ordered_before?
  end

  test "配對的列：確認對話框提到搭配的另一家" do
    group = create(:order_group, event: @event)
    create(:order_inquiry, event: @event, merchant: create(:merchant, :drink_only, name: "涼飲店"), order_group: group)
    @inquiry.update!(order_group: group)

    get inquiries_path

    assert_select "form[data-turbo-confirm*='與搭配的「涼飲店」都已訂購']"
  end

  test "活動日期已過的詢問單也能記錄訂購" do
    past_event = create(:event, held_on: Date.new(2026, 9, 29))
    old = create(:order_inquiry, event: past_event, merchant: create(:merchant))

    post inquiry_confirmation_path(old)

    assert old.reload.confirmed?
    assert_equal Date.new(2026, 9, 29), old.order_record.ordered_on
  end

  test "不存在的詢問單回 404" do
    post inquiry_confirmation_path(inquiry_id: 0)

    assert_response :not_found
  end

  test "需要 Basic Auth" do
    with_env(AUTH_ENV) do
      post inquiry_confirmation_path(@inquiry)
      assert_response :unauthorized
      assert @inquiry.reload.sent?

      delete inquiry_confirmation_path(@inquiry)
      assert_response :unauthorized
    end
  end
end
