# 詢問訊息預覽。畫面上的文字就是複製出去的文字（同一個 InquiryMessage），所以用 <pre> 原樣顯示，
# 複製按鈕讀的是這個元素的 textContent。複製失敗時 inquiry controller 會反白這段文字讓使用者手動複製。
class MessagePreviewComponent < ViewComponent::Base
  # notice：訊息旁的提醒（例如「活動日期已過，請確認再送出」）
  def initialize(text:, notice: nil)
    @text = text
    @notice = notice
  end

  attr_reader :text, :notice
end
