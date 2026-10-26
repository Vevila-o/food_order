require "test_helper"

class KindBadgeComponentTest < ViewComponent::TestCase
  test "餐＋飲用 accent 強調色" do
    render_inline(KindBadgeComponent.new(kind: :food_and_drink))

    assert_selector "span.bg-accent.font-bold", text: "餐＋飲"
  end

  test "只有餐用 soft" do
    render_inline(KindBadgeComponent.new(kind: :food_only))

    assert_selector "span.bg-soft", text: "只有餐"
  end

  test "僅飲料用 secondary" do
    render_inline(KindBadgeComponent.new(kind: :drink_only))

    assert_selector "span.bg-secondary", text: "僅飲料"
  end

  test "每種 Merchant#kind 都有對應色調與中文翻譯" do
    assert_equal %i[drink_only food_and_drink food_only], KindBadgeComponent::TONES.keys.sort
    KindBadgeComponent::TONES.each_key do |kind|
      assert I18n.exists?("merchant_kind.#{kind}"), "缺少翻譯 merchant_kind.#{kind}"
    end
  end
end
