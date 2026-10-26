# 首頁：距離下一場 Ruby Jam 開始的倒數（天 / 時）。依伺服器的當下時間算，頁面載入時的數字
# （天、時的精度不需要每分鐘更新）。活動已開始或日期已過就顯示「已開始或已結束」並提示設定下一場。
class CountdownCardComponent < ViewComponent::Base
  # edit_href：「設定下一場」連結（沒給就不顯示）；now：測試與預覽用
  def initialize(event:, edit_href: nil, now: Time.current)
    @event = event
    @edit_href = edit_href
    @countdown = event.countdown(now)
  end

  attr_reader :event, :edit_href, :countdown

  def started? = countdown.started

  # 兩位數顯示：05
  def days_text = format("%02d", countdown.days)

  def hours_text = format("%02d", countdown.hours)

  # 螢幕閱讀器唸的完整句子（數字方塊本身是裝飾）
  def spoken_text
    return "下一場 Ruby Jam 已開始或已結束" if started?

    "距離下一場 Ruby Jam 還有 #{countdown.days} 天 #{countdown.hours} 小時"
  end
end
