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

  test "show_label：桌機多顯示文字（圖示旁），文字對讀屏隱藏避免重複唸；手機仍只有圖示" do
    render_inline(IconLinkComponent.new(icon: :settings, label: "設定", href: "/setting/edit", show_label: true))

    assert_selector "a[aria-label=設定].md\\:w-auto"
    assert_selector "a span.hidden.md\\:inline[aria-hidden=true]", text: "設定"
  end

  test "沒有 show_label：只有圖示的圓形，沒有文字" do
    render_inline(IconLinkComponent.new(icon: :plus, label: "新增店家", href: "/merchants/new"))

    assert_no_selector "a span"
    assert_no_selector "a.md\\:w-auto"
  end
end
