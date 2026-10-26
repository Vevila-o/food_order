require "test_helper"

class MessagePreviewComponentTest < ViewComponent::TestCase
  TEXT = "您好！\n- 雞腿便當 × 18 份\n謝謝！".freeze

  test "原樣顯示訊息（pre），換行保留，前後沒有多餘空白" do
    render_inline(MessagePreviewComponent.new(text: TEXT))

    pre = page.find("pre[data-inquiry-target=message]")
    assert_equal TEXT, pre.native.text
  end

  test "可聚焦、可全選（複製失敗時手動複製）" do
    render_inline(MessagePreviewComponent.new(text: TEXT))

    assert_selector "pre[tabindex='0'].select-all"
  end

  test "訊息內容會跳脫，不會當成 HTML" do
    render_inline(MessagePreviewComponent.new(text: "<script>alert(1)</script>"))

    assert_no_selector "script"
    assert_text "<script>alert(1)</script>"
  end

  test "有 notice 才顯示提醒" do
    render_inline(MessagePreviewComponent.new(text: TEXT))
    assert_no_selector "[role=note]"

    render_inline(MessagePreviewComponent.new(text: TEXT, notice: "活動日期已過"))
    assert_selector "p[role=note]", text: "活動日期已過"
  end
end
