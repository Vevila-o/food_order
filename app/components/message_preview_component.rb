# 詢問訊息預覽。畫面上的文字就是複製出去的文字（同一個 InquiryMessage），所以用 <pre> 原樣顯示，
# 複製讀的是這個元素的 textContent。複製失敗時 inquiry controller 會反白這段文字讓使用者手動複製。
# 右上角有複製按鈕與鉛筆（編輯）：編輯時 <pre> 換成文字框，按「完成」才儲存；改了品項或數量，訊息會重新產生。
class MessagePreviewComponent < ViewComponent::Base
  # dom_id：這則訊息的元素 id（兩家並存時，按鈕靠它找到「自己那一則」）；title：兩家時帶店名；
  # notice：訊息旁的提醒（例如「活動日期已過，請確認再送出」）；
  # merchant_id：這則訊息屬於哪家店（儲存手動修改時要用）；edited：目前顯示的是手動改過的版本
  def initialize(text:, dom_id: "inquiry-message", title: "詢問訊息", notice: nil, merchant_id: nil, edited: false)
    @text = text
    @dom_id = dom_id
    @title = title
    @notice = notice
    @merchant_id = merchant_id
    @edited = edited
  end

  attr_reader :text, :dom_id, :title, :notice, :merchant_id

  def edited? = @edited

  def editor_id = "#{dom_id}-editor"

  def icon_button_class
    "inline-flex size-11 cursor-pointer items-center justify-center rounded-full bg-base-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-base-content"
  end
end
