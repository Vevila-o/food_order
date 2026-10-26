# 詢問訊息預覽。畫面上的文字就是複製出去的文字（同一個 InquiryMessage），所以用 <pre> 原樣顯示，
# 複製按鈕讀的是這個元素的 textContent。複製失敗時 inquiry controller 會反白這段文字讓使用者手動複製。
class MessagePreviewComponent < ViewComponent::Base
  # dom_id：這則訊息的元素 id（兩家並存時，聯絡按鈕靠它找到「自己那一則」）；title：兩家時帶店名；
  # notice：訊息旁的提醒（例如「活動日期已過，請確認再送出」）
  def initialize(text:, dom_id: "inquiry-message", title: "詢問訊息", notice: nil)
    @text = text
    @dom_id = dom_id
    @title = title
    @notice = notice
  end

  attr_reader :text, :dom_id, :title, :notice
end
