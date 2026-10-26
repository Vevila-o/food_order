require "test_helper"

class OrderedDotComponentTest < ViewComponent::TestCase
  test "曾訂購：橘色（accent）圓點加文字" do
    render_inline(OrderedDotComponent.new(ordered: true))

    assert_selector "span.bg-accent[aria-hidden=true]"
    assert_selector "span.border", count: 1 # 圓點有外框，淺色在白底上也看得清楚
    assert_text "曾訂購"
    assert_selector "[data-ordered=true]"
  end

  test "沒訂過：灰色圓點加文字" do
    render_inline(OrderedDotComponent.new(ordered: false))

    assert_selector "span.bg-gray-300"
    assert_text "沒訂過"
    assert_no_selector ".bg-accent"
  end

  test "圓點是裝飾，狀態一定用文字表達（不能只靠顏色）" do
    render_inline(OrderedDotComponent.new(ordered: true))

    assert_selector "span[aria-hidden=true]:empty"
    assert_text "曾訂購"
  end
end
