require "test_helper"

class AlertComponentTest < ViewComponent::TestCase
  test "依類型套用 daisyUI 樣式並帶 role=alert" do
    render_inline(AlertComponent.new(type: :notice)) { "已儲存" }

    assert_selector "div[role=alert].alert.alert-success", text: "已儲存"
  end

  test "alert 為警告樣式" do
    render_inline(AlertComponent.new(type: :alert)) { "有問題" }

    assert_selector ".alert-warning"
  end

  test "未知類型退回一般樣式，type 可為字串（flash 的 key 是字串）" do
    render_inline(AlertComponent.new(type: "whatever")) { "訊息" }

    assert_selector ".alert-info"
  end

  test "訊息內容會被跳脫，不會當成 HTML" do
    render_inline(AlertComponent.new(type: :info)) { "<script>alert(1)</script>" }

    assert_no_selector "script"
  end
end
