require "test_helper"

class PillComponentTest < ViewComponent::TestCase
  test "各種色調對應色票" do
    {
      accent: "bg-accent", soft: "bg-soft", secondary: "bg-secondary",
      warning: "bg-warning", base: "bg-base-200"
    }.each do |tone, css|
      render_inline(PillComponent.new(tone: tone)) { "文字" }
      assert_selector "span.rounded-full.#{css}", text: "文字"
    end
  end

  test "強調色用粗體" do
    render_inline(PillComponent.new(tone: :accent)) { "餐＋飲" }

    assert_selector "span.font-bold"
  end

  test "不認得的色調直接報錯" do
    assert_raises(KeyError) { render_inline(PillComponent.new(tone: :neon)) { "x" } }
  end
end
