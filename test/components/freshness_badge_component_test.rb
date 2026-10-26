require "test_helper"

class FreshnessBadgeComponentTest < ViewComponent::TestCase
  test "有效：低調的 ghost" do
    render_inline(FreshnessBadgeComponent.new(freshness: :fresh))

    assert_selector ".badge.badge-ghost", text: "菜單有效"
  end

  test "過期：醒目的 warning 並寫明可能過期" do
    render_inline(FreshnessBadgeComponent.new(freshness: :stale))

    assert_selector ".badge.badge-warning", text: "菜單可能過期"
  end

  test "日期不明：同樣醒目" do
    render_inline(FreshnessBadgeComponent.new(freshness: :unknown))

    assert_selector ".badge.badge-warning", text: "日期不明"
  end
end
