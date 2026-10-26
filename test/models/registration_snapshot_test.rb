require "test_helper"

class RegistrationSnapshotTest < ActiveSupport::TestCase
  test "人數不可為負" do
    assert_not build(:registration_snapshot, headcount: -1).valid?
    assert build(:registration_snapshot, headcount: 0).valid?
  end

  test "沒填收到時間時自動帶入現在" do
    assert_not_nil create(:registration_snapshot).received_at
  end

  test "同一筆訂單 + 事件類型重送不重複計算" do
    event = create(:event)
    create(:registration_snapshot, :webhook, event: event, kktix_order_id: "A1")

    duplicate = build(:registration_snapshot, :webhook, event: event, kktix_order_id: "A1")
    assert_not duplicate.valid?
  end

  test "資料庫的部分唯一索引也擋重複（即使跳過驗證）" do
    event = create(:event)
    create(:registration_snapshot, :webhook, event: event, kktix_order_id: "A1")

    assert_raises(ActiveRecord::RecordNotUnique) do
      # 跳過驗證也會跳過 before_validation，所以 received_at 要自己帶
      build(:registration_snapshot, :webhook, event: event, kktix_order_id: "A1", received_at: Time.current).save!(validate: false)
    end
  end

  test "同一訂單的付款與取消是不同事件，可以並存" do
    event = create(:event)
    create(:registration_snapshot, event: event, source: "webhook", kktix_order_id: "A1", kktix_event_type: "order_paid")

    assert build(:registration_snapshot, event: event, source: "webhook", kktix_order_id: "A1", kktix_event_type: "order_cancelled").valid?
  end

  test "手動修正沒有訂單 ID，可以有多筆" do
    event = create(:event)
    create(:registration_snapshot, event: event)

    assert build(:registration_snapshot, event: event).valid?
  end

  test "source 只接受 webhook / manual" do
    assert_not build(:registration_snapshot, source: "email").valid?
  end
end
