require "test_helper"

class HeaderComponentTest < ViewComponent::TestCase
  test "品牌連回首頁" do
    render_inline(HeaderComponent.new)

    assert_selector "header a[href='/']", text: "Ruby Jam 訂餐助手"
  end

  test "導覽列有新增店家" do
    render_inline(HeaderComponent.new)

    assert_selector "nav[aria-label='主要導覽'] a[href='/merchants/new']", text: "新增店家"
  end
end
