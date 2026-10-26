require "test_helper"

class IconLinkComponentTest < ViewComponent::TestCase
  test "只有圖示的連結一定有 aria-label" do
    render_inline(IconLinkComponent.new(icon: :plus, label: "新增店家", href: "/merchants/new"))

    assert_selector "a[href='/merchants/new'][aria-label='新增店家'].btn-circle.btn-primary"
    assert_selector "a svg[aria-hidden=true]"
  end

  test "plain 變體" do
    render_inline(IconLinkComponent.new(icon: :plus, label: "新增", href: "/", variant: :plain))

    assert_selector "a.bg-base-200"
  end
end
