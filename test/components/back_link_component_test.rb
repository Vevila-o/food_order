require "test_helper"

class BackLinkComponentTest < ViewComponent::TestCase
  test "返回連結：文字、網址、44px 點擊範圍" do
    render_inline(BackLinkComponent.new(label: "返回列表", href: "/merchants"))

    assert_selector "a.tap-target[href='/merchants']", text: "返回列表"
    assert_selector "a svg[aria-hidden=true]"
  end
end
