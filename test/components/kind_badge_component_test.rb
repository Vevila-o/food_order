require "test_helper"

class KindBadgeComponentTest < ViewComponent::TestCase
  test "餐＋飲用 accent 色票" do
    render_inline(KindBadgeComponent.new(kind: :food_and_drink))

    assert_selector ".badge.badge-accent", text: "餐＋飲"
  end

  test "只有餐" do
    render_inline(KindBadgeComponent.new(kind: :food_only))

    assert_selector ".badge", text: "只有餐"
  end

  test "僅飲料用 secondary" do
    render_inline(KindBadgeComponent.new(kind: :drink_only))

    assert_selector ".badge.badge-secondary", text: "僅飲料"
  end

  test "每種 Merchant#kind 都有對應樣式" do
    KindBadgeComponent::STYLES.each_key do |kind|
      assert I18n.exists?("merchant_kind.#{kind}"), "缺少翻譯 merchant_kind.#{kind}"
    end
  end
end
