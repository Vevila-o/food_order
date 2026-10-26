require "test_helper"

class FreshnessBadgeComponentTest < ViewComponent::TestCase
  test "有效：低調的一般色" do
    render_inline(FreshnessBadgeComponent.new(freshness: :fresh))

    assert_selector "span.bg-base-200", text: "菜單有效"
  end

  test "過期：醒目的 secondary 並寫明可能過期" do
    render_inline(FreshnessBadgeComponent.new(freshness: :stale))

    assert_selector "span.bg-secondary", text: "菜單可能過期"
  end

  test "日期不明：同樣醒目" do
    render_inline(FreshnessBadgeComponent.new(freshness: :unknown))

    assert_selector "span.bg-secondary", text: "日期不明"
  end
end
