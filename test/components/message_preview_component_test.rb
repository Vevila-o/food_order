require "test_helper"

class MessagePreviewComponentTest < ViewComponent::TestCase
  TEXT = "您好！\n- 雞腿便當 × 18 份\n謝謝！".freeze

  test "原樣顯示訊息（pre），換行保留，前後沒有多餘空白" do
    render_inline(MessagePreviewComponent.new(text: TEXT))

    pre = page.find("pre[data-inquiry-message]")
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

  test "dom_id 與標題可指定（兩家並存時，每顆聯絡按鈕靠 id 找到自己那一則）" do
    render_inline(MessagePreviewComponent.new(text: TEXT, dom_id: "inquiry-message-12", title: "詢問訊息 · 涼飲店"))

    assert_selector "pre#inquiry-message-12"
    assert_selector "h2", text: "詢問訊息 · 涼飲店"
  end

  test "預設 id 與標題" do
    render_inline(MessagePreviewComponent.new(text: TEXT))

    assert_selector "pre#inquiry-message"
    assert_selector "h2", text: "詢問訊息"
  end
end
