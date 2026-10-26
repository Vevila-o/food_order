require "test_helper"

class PageHeaderComponentTest < ViewComponent::TestCase
  test "標題是 h1" do
    render_inline(PageHeaderComponent.new(title: "找今晚的餐"))

    assert_selector "header h1", text: "找今晚的餐"
  end

  test "品牌小字與副標" do
    render_inline(PageHeaderComponent.new(title: "標題", eyebrow: "Ruby Jam 訂餐助手", subtitle: "大安區 · 0.6 公里"))

    assert_text "Ruby Jam 訂餐助手"
    assert_text "大安區 · 0.6 公里"
  end

  test "slots：返回連結、右上角動作、summary" do
    render_inline(PageHeaderComponent.new(title: "標題")) do |header|
      header.with_back_link { "<a href='/'>返回</a>".html_safe }
      header.with_actions { "<button>動作</button>".html_safe }
      header.with_summary { "<p>摘要</p>".html_safe }
    end

    assert_selector "a", text: "返回"
    assert_selector "button", text: "動作"
    assert_selector "p", text: "摘要"
  end

  test "沒有 slots 時不產生多餘區塊" do
    render_inline(PageHeaderComponent.new(title: "標題"))

    assert_no_selector "a"
    assert_no_selector "button"
    assert_no_selector "p"
  end

  test "標題文字會被跳脫" do
    render_inline(PageHeaderComponent.new(title: "<script>alert(1)</script>"))

    assert_no_selector "script"
  end
end
