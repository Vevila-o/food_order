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

  test "右上角有複製與編輯（鉛筆）按鈕，帶訊息元素 id，圖示、標題與說明文字齊全" do
    render_inline(MessagePreviewComponent.new(text: TEXT, dom_id: "inquiry-message-7"))

    assert_selector "[data-message-toolbar] button[aria-label=複製訊息][title=複製訊息][data-inquiry-message-id-param=inquiry-message-7] svg"
    assert_selector "[data-message-toolbar] button[aria-label=編輯訊息][title=編輯訊息][data-inquiry-message-id-param=inquiry-message-7] svg"
    assert_selector "button.size-11", count: 2
  end

  test "編輯區平常隱藏：文字框沒有 name（不會被數量表單帶出去）、有標籤、有完成與取消" do
    render_inline(MessagePreviewComponent.new(text: TEXT, dom_id: "inquiry-message-7"))

    assert_selector "div[data-message-editor][hidden]", visible: :all
    assert_selector "textarea#inquiry-message-7-editor[maxlength='2000']:not([name])", visible: :all
    assert_selector "label[for=inquiry-message-7-editor]", visible: :all
    assert_selector "button[data-action='inquiry#finishEdit']", text: "完成", visible: :all
    assert_selector "button[data-action='inquiry#cancelEdit']", text: "取消", visible: :all
  end

  test "edited：顯示已編輯標籤，pre 帶 data-edited 與店家 id" do
    render_inline(MessagePreviewComponent.new(text: TEXT, merchant_id: 7, edited: true))

    assert_selector "h2 span", text: "已編輯"
    assert_selector "pre[data-edited][data-merchant-id='7']"
  end

  test "沒編輯過：沒有已編輯標籤與 data-edited" do
    render_inline(MessagePreviewComponent.new(text: TEXT, merchant_id: 7))

    assert_no_selector "h2 span"
    assert_no_selector "pre[data-edited]"
  end

  test "有自己的狀態文字區（複製與儲存結果顯示在這裡）" do
    render_inline(MessagePreviewComponent.new(text: TEXT))

    assert_selector "p[role=status][aria-live=polite][data-inquiry-status]"
  end
end
