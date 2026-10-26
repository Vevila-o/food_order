require "test_helper"

class HomePageTest < ActionDispatch::IntegrationTest
  setup do
    with_env("ACCESS_USER" => nil, "ACCESS_PASSWORD" => nil) { get root_path }
  end

  test "首頁顯示專案名稱" do
    assert_response :success
    assert_select "h1", "Ruby Jam 訂餐助手"
    assert_select "title", "Ruby Jam 訂餐助手"
  end

  test "使用 zh-TW 與自訂 daisyUI theme" do
    assert_select "html[lang=zh-TW][data-theme=rubyjam]"
  end

  test "iOS 適配：viewport-fit=cover 與 PWA manifest" do
    assert_select "meta[name=viewport][content*='viewport-fit=cover']"
    assert_select "link[rel=manifest]"
  end

  test "回應帶有 CSP header 並允許 OSM 圖磚" do
    csp = response.headers["Content-Security-Policy"]
    assert_includes csp, "default-src 'self'"
    assert_includes csp, "https://*.tile.openstreetmap.org"
    assert_includes csp, "object-src 'none'"
  end
end
