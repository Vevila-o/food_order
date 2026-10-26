require "test_helper"

class EventSummaryComponentTest < ViewComponent::TestCase
  setup { travel_to Time.zone.local(2026, 10, 22, 12, 0) }

  def render_summary(event) = render_inline(EventSummaryComponent.new(event: event))

  test "日期、星期與送達時段" do
    render_summary(create(:event, :with_headcount, held_on: Date.new(2026, 10, 27)))

    assert_text "下一場 Ruby Jam · 10/27（二）"
    assert_text "19:00–19:15 送達"
  end

  test "報名人數與總預算（人數 × NT$100）" do
    render_summary(create(:event, :with_headcount, headcount: 18))

    assert_selector "dd", text: "18 人"
    assert_selector "dd", text: "NT$1,800"
  end

  test "還沒填人數：顯示尚未填寫，預算用破折號" do
    render_summary(create(:event))

    assert_selector "dd", text: "尚未填寫"
    assert_selector "dd", text: "—"
    assert_no_text "需調整訂餐"
  end

  test "人數比詢問單建立時多：提示需調整訂餐" do
    event = create(:event, :with_headcount, headcount: 18)
    create(:order_inquiry, event: event, headcount_at_creation: 16)

    render_summary(event.reload)

    assert_selector "span.bg-warning", text: "比上次詢問 +2 人，需調整訂餐"
  end

  test "人數變少：顯示減號" do
    event = create(:event, :with_headcount, headcount: 15)
    create(:order_inquiry, event: event, headcount_at_creation: 18)

    render_summary(event.reload)

    assert_text "比上次詢問 −3 人，需調整訂餐"
  end

  test "人數與詢問單一致：不提示" do
    event = create(:event, :with_headcount, headcount: 18)
    create(:order_inquiry, event: event, headcount_at_creation: 18)

    render_summary(event.reload)

    assert_no_text "需調整訂餐"
  end

  test "多張詢問單：以最近建立、人數已不同的那張為準" do
    event = create(:event, :with_headcount, headcount: 20)
    create(:order_inquiry, event: event, headcount_at_creation: 15, created_at: 3.days.ago)
    create(:order_inquiry, event: event, headcount_at_creation: 18, created_at: 1.day.ago)

    render_summary(event.reload)

    assert_text "比上次詢問 +2 人"
  end

  test "KKTIX 後台連結：開新分頁並帶 noopener" do
    render_summary(create(:event, :with_headcount, kktix_slug: "rubyjam2610"))

    assert_selector "a[href='https://kktix.com/dashboard/events/rubyjam2610/attendees'][target=_blank][rel~=noopener]", text: "KKTIX 後台"
  end
end
