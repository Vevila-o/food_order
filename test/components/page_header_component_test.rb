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

  test "麵包屑：有給才顯示，首頁不給就沒有" do
    render_inline(PageHeaderComponent.new(title: "標題", breadcrumb: [ [ "收藏" ] ]))
    assert_selector "nav[aria-label=麵包屑] span[aria-current=page]", text: "收藏"

    render_inline(PageHeaderComponent.new(title: "標題"))
    assert_no_selector "nav[aria-label=麵包屑]"
  end

  test "slots：右上角動作、summary" do
    render_inline(PageHeaderComponent.new(title: "標題")) do |header|
      header.with_actions { "<button>動作</button>".html_safe }
      header.with_summary { "<p>摘要</p>".html_safe }
    end

    assert_selector "button", text: "動作"
    assert_selector "p", text: "摘要"
  end

  test "沒有 slots 時不產生多餘區塊" do
    render_inline(PageHeaderComponent.new(title: "標題"))

    assert_no_selector "a"
    assert_selector "button", count: 1 # 只有手機的選單按鈕
    assert_no_selector "p"
  end

  test "標題文字會被跳脫" do
    render_inline(PageHeaderComponent.new(title: "<script>alert(1)</script>"))

    assert_no_selector "script"
  end

  test "手機的選單按鈕：開側欄抽屜，只在手機顯示（md:hidden），有 aria-label 與 44px 範圍" do
    render_inline(PageHeaderComponent.new(title: "標題"))

    assert_selector "button.md\\:hidden[aria-label=開啟選單][data-action='dialog#open'].size-11"
  end
end
