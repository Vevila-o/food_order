require "test_helper"

class OrderInquiryTest < ActiveSupport::TestCase
  test "預設為草稿" do
    assert create(:order_inquiry).draft?
  end

  test "一場活動對同一店家只有一張詢問單" do
    inquiry = create(:order_inquiry)

    assert_not build(:order_inquiry, event: inquiry.event, merchant: inquiry.merchant).valid?
  end

  test "同一店家在不同活動可各有詢問單" do
    inquiry = create(:order_inquiry)

    assert build(:order_inquiry, merchant: inquiry.merchant).valid?
  end

  test "外送費未知時預計金額也是 NULL，不是 0" do
    inquiry = create(:order_inquiry, :fee_unknown)

    assert_nil inquiry.delivery_fee
    assert_nil inquiry.total
  end

  test "需調整訂餐：最新人數與建立時人數不同" do
    event = create(:event)
    inquiry = create(:order_inquiry, event: event, headcount_at_creation: 18)

    assert_not inquiry.needs_adjustment?, "還沒有人數快照時不提示"

    create(:registration_snapshot, event: event, headcount: 18)
    assert_not inquiry.needs_adjustment?

    create(:registration_snapshot, event: event, headcount: 20, received_at: 1.minute.from_now)
    assert inquiry.needs_adjustment?
  end

  test "點聯絡按鈕：標為 sent 並記錄管道與時間" do
    inquiry = create(:order_inquiry)

    inquiry.mark_sent!(:line)

    assert inquiry.sent?
    assert inquiry.via_line?
    assert_not_nil inquiry.sent_at
  end

  test "已確認的詢問單不會被按鈕降級" do
    inquiry = create(:order_inquiry)
    inquiry.confirm!

    inquiry.mark_sent!(:phone)

    assert inquiry.reload.confirmed?
  end

  test "聯絡管道只接受已知值" do
    assert_not build(:order_inquiry, contacted_via: "fax").valid?
  end

  test "確認訂購：改狀態並自動建立歷史訂購紀錄" do
    event = create(:event, held_on: Date.new(2026, 10, 27))
    inquiry = create(:order_inquiry, event: event, headcount_at_creation: 18, total: 1620)

    assert_difference "OrderRecord.count", 1 do
      inquiry.confirm!
    end

    record = inquiry.order_record
    assert inquiry.confirmed?
    assert record.source_inquiry?
    assert_equal Date.new(2026, 10, 27), record.ordered_on
    assert_equal 18, record.headcount
    assert_equal 1620, record.total
    assert_equal inquiry.merchant, record.merchant
  end

  test "重複確認不會產生第二筆紀錄" do
    inquiry = create(:order_inquiry)
    inquiry.confirm!

    assert_no_difference "OrderRecord.count" do
      inquiry.confirm!
    end
  end

  test "取消確認：退回 sent 並刪除自動產生的紀錄" do
    inquiry = create(:order_inquiry)
    inquiry.mark_sent!(:line)
    inquiry.confirm!

    assert_difference "OrderRecord.count", -1 do
      inquiry.unconfirm!
    end

    assert inquiry.reload.sent?
  end

  test "沒按過聯絡按鈕就取消確認，退回草稿" do
    inquiry = create(:order_inquiry)
    inquiry.confirm!

    inquiry.unconfirm!

    assert inquiry.reload.draft?
  end

  test "刪除詢問單會一併刪除品項與自動產生的紀錄" do
    inquiry = create(:order_inquiry)
    create(:order_inquiry_item, order_inquiry: inquiry)
    inquiry.confirm!

    assert_difference [ "OrderInquiryItem.count", "OrderRecord.count" ], -1 do
      inquiry.destroy!
    end
  end

  test "詢問單品項是快照：菜單項目被刪除後仍保留名稱與單價" do
    menu_item = create(:menu_item, name: "雞腿飯", price: 90)
    item = create(:order_inquiry_item, menu_item: menu_item, name: "雞腿飯", unit_price: 90)

    menu_item.destroy!
    item.reload

    assert_nil item.menu_item_id
    assert_equal "雞腿飯", item.name
    assert_equal 90, item.unit_price
  end
end
