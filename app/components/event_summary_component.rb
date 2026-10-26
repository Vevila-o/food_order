# 首頁頂部的活動摘要卡（設計稿）：下一場日期與送達時段、報名人數、總預算、「需調整訂餐」提示、KKTIX 後台連結。
# 人數目前是手動輸入（「修正人數」連到活動設定頁），M3 起由 KKTIX Webhook 更新。
class EventSummaryComponent < ViewComponent::Base
  # edit_href：「修正人數」連結（沒給就不顯示，預覽與測試不需要路由）
  def initialize(event:, edit_href: nil)
    @event = event
    @edit_href = edit_href
    @headcount = event.headcount
    @inquiries = event.order_inquiries.to_a
  end

  attr_reader :event, :headcount, :edit_href

  # 「10/27（二）」
  def date_text = "#{event.held_on.month}/#{event.held_on.day}（#{event.weekday_label.delete_prefix('週')}）"

  def headcount_text = headcount ? "#{headcount} 人" : "尚未填寫"

  def budget_text = event.total_budget ? helpers.format_money(event.total_budget) : "—"

  # 比「最近建立的、人數已不同的詢問單」多（或少）幾人；沒有需要調整的詢問單時為 nil
  def adjustment_delta
    return unless headcount

    stale = @inquiries.select { |inquiry| inquiry.headcount_at_creation != headcount }
    latest = stale.max_by(&:created_at)
    latest && headcount - latest.headcount_at_creation
  end

  def adjustment_text
    delta = adjustment_delta
    return unless delta

    "比上次詢問 #{delta.positive? ? '+' : '−'}#{delta.abs} 人，需調整訂餐"
  end
end
