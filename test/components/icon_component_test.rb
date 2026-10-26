require "test_helper"

class IconComponentTest < ViewComponent::TestCase
  test "輸出裝飾用的 SVG（aria-hidden），stroke 跟著文字色" do
    render_inline(IconComponent.new(name: :plus))

    assert_selector "svg[aria-hidden=true][stroke=currentColor][viewbox='0 0 24 24'][width='20'][height='20']"
    assert_selector "svg path[d='M12 5v14M5 12h14']"
  end

  test "可指定大小與 class（填色用 Tailwind fill class）" do
    render_inline(IconComponent.new(name: :star, size: 28, class: "fill-accent"))

    assert_selector "svg.fill-accent[width='28'][height='28']"
  end

  test "每個圖示都有路徑資料" do
    IconComponent::PATHS.each_key do |name|
      render_inline(IconComponent.new(name: name))
      assert_selector "svg path[d]", count: 1
    end
  end

  test "不存在的圖示直接報錯，不會默默輸出空白" do
    assert_raises(KeyError) { render_inline(IconComponent.new(name: :nope)) }
  end
end
