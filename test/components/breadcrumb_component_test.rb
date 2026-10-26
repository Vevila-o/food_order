require "test_helper"

class BreadcrumbComponentTest < ViewComponent::TestCase
  test "第一層永遠是首頁，是有名稱的導覽區域" do
    render_inline(BreadcrumbComponent.new(items: [ [ "收藏" ] ]))

    assert_selector "nav[aria-label=麵包屑] ol li", count: 2
    assert_selector "ol li:first-child a[href='/']", text: "首頁"
  end

  test "最後一層是目前頁面：不是連結、有 aria-current" do
    render_inline(BreadcrumbComponent.new(items: [ [ "店", "/merchants/1" ], [ "編輯" ] ]))

    assert_selector "span[aria-current=page]", text: "編輯", count: 1
    assert_no_selector "a", text: "編輯"
    assert_selector "a[href='/merchants/1']", text: "店"
  end

  test "連結高度 44px（min-h-11），分隔箭頭是裝飾" do
    render_inline(BreadcrumbComponent.new(items: [ [ "店", "/merchants/1" ], [ "編輯" ] ]))

    assert_selector "a.min-h-11", count: 2
    assert_selector "li svg[aria-hidden=true]", count: 2
  end

  test "店名中的 HTML 會被跳脫" do
    render_inline(BreadcrumbComponent.new(items: [ [ "<img src=x onerror=alert(1)>", "/merchants/1" ], [ "編輯" ] ]))

    assert_no_selector "img"
  end
end
