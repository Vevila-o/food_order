# 詢問店家的訊息（規格書 F-06 範本）。畫面預覽、複製到剪貼簿、存進 order_inquiries.message_text 都用這一份，
# 所以三處的文字與金額一定一致。
#
#   InquiryMessage.new(event:, location:, lines:, subtotal:, recipient:, invoice:).text
#
# lines：[Line, ...]（品名、單位、數量）。「（週二）」由活動日期計算，不寫死。
# 收件資訊（recipient）與發票統編（invoice）有填才各加一行；地點一律寫。
# 不再附「確認菜單價格是否有調整」（使用者要求拿掉）。
class InquiryMessage
  Line = Data.define(:name, :unit, :quantity)

  def initialize(event:, location:, lines:, subtotal:, recipient: nil, invoice: nil)
    @event = event
    @location = location
    @lines = lines
    @subtotal = subtotal
    @recipient = recipient
    @invoice = invoice
  end

  def text
    [
      "您好！想詢問 #{date_text}（#{@event.weekday_label}）#{@event.delivery_window_label} 之間，是否能外送以下餐點到 #{@location}：",
      *@lines.map { |line| "- #{line.name} × #{quantity_text(line)}" },
      @recipient.presence,
      @invoice.presence,
      "依菜單價格估計小計約 NT$#{ActiveSupport::NumberHelper.number_to_delimited(@subtotal)}。",
      "想請問是否需要外送費？",
      "謝謝！"
    ].compact.join("\n")
  end

  alias_method :to_s, :text

  private

  # 「10/27」
  def date_text = "#{@event.held_on.month}/#{@event.held_on.day}"

  # 有單位就寫「18 份」，沒有就只寫數字
  def quantity_text(line) = [ line.quantity, line.unit.presence ].compact.join(" ")
end
