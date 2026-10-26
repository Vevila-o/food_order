require "test_helper"

class OrderRecordTest < ActiveSupport::TestCase
  test "手動補登可以不填日期（曾訂過但不記得哪次）" do
    assert build(:order_record, ordered_on: nil).valid?
  end

  test "訂購日期不可晚於今天" do
    assert_not build(:order_record, ordered_on: Date.current + 1).valid?
  end

  test "日期倒序排列，日期不明的排最後" do
    unknown = create(:order_record, ordered_on: nil)
    old = create(:order_record, ordered_on: Date.new(2026, 7, 21))
    recent = create(:order_record, ordered_on: Date.new(2026, 9, 15))

    assert_equal [ recent, old, unknown ], OrderRecord.recent_first.to_a
  end

  test "一張詢問單只會有一筆自動紀錄（資料庫唯一索引）" do
    inquiry = create(:order_inquiry)
    create(:order_record, merchant: inquiry.merchant, order_inquiry: inquiry, source: "inquiry")

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:order_record, merchant: inquiry.merchant, order_inquiry: inquiry, source: "inquiry").save!(validate: false)
    end
  end

  test "source 只接受 inquiry / manual" do
    assert_not build(:order_record, source: "import").valid?
  end

  test "活動被刪除時紀錄保留（event 清空）" do
    event = create(:event)
    record = create(:order_record, event: event)

    event.destroy!

    assert_nil record.reload.event_id
  end
end
