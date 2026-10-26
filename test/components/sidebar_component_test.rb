require "test_helper"

class SidebarComponentTest < ViewComponent::TestCase
  def render_sidebar(path = "/", counts = {})
    render_inline(SidebarComponent.new(current_path: path, counts: counts))
  end

  test "六個項目，順序固定，連到對應頁面" do
    render_sidebar

    links = page.all("nav a").map { |a| [ a.text.strip, a[:href] ] }
    assert_equal(
      [ [ "全部店家", "/" ], [ "瀏覽歷史", "/history" ], [ "收藏", "/favorites" ], [ "下次訂購", "/shortlist" ], [ "已詢問", "/inquiries" ], [ "已訂購", "/orders" ] ],
      links
    )
  end

  test "是有名稱的導覽區域" do
    render_sidebar

    assert_selector "nav[aria-label='主要選單']"
  end

  test "目前頁面用 aria-current 標示並以 primary 強調" do
    render_sidebar("/favorites")

    assert_selector "a[aria-current=page]", count: 1
    assert_selector "a[aria-current=page].bg-primary", text: "收藏"
  end

  test "全部店家涵蓋首頁與 /merchants 底下所有頁面" do
    %w[/ /merchants /merchants/12 /merchants/new /merchants/12/edit /merchants/12/menu_import/new].each do |path|
      render_sidebar(path)
      assert_selector "a[aria-current=page]", text: "全部店家", count: 1
    end
  end

  test "其他頁面各自只有自己是目前頁面" do
    { "/history" => "瀏覽歷史", "/favorites" => "收藏", "/shortlist" => "下次訂購", "/inquiries" => "已詢問", "/orders" => "已訂購" }.each do |path, label|
      render_sidebar(path)
      assert_selector "a[aria-current=page]", text: label, count: 1
      assert_no_selector "a[aria-current=page]", text: "全部店家"
    end
  end

  test "不相關的網址沒有目前頁面" do
    render_sidebar("/up")

    assert_no_selector "a[aria-current]"
  end

  test "顯示各項目的數量，0 或沒給就不顯示" do
    render_sidebar("/", { history: 8, favorites: 3, shortlist: 2, inquiries: 0, orders: nil })

    assert_selector "a", text: /瀏覽歷史\s*8/
    assert_selector "a", text: /收藏\s*3/
    assert_selector "a", text: /下次訂購\s*2/
    assert_no_selector "a", text: /已詢問\s*\d/
    assert_no_selector "a", text: /已訂購\s*\d/
  end

  test "每個項目都是 44px 高、圖示是裝飾（aria-hidden）" do
    render_sidebar

    assert_selector "a.min-h-11", count: 6
    assert_selector "a svg[aria-hidden=true]", count: 6
  end

  test "每個項目都有圖示與路由" do
    SidebarComponent::ITEMS.each do |item|
      assert IconComponent::PATHS.key?(item.icon), "缺少圖示 #{item.icon}"
      assert_respond_to Rails.application.routes.url_helpers, item.route
    end
  end
end
