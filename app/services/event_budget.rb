# 一場活動的預算：總預算（人數 × NT$100）與「本場合計」（所有詢問單的預計金額加總）比較。
# 一場活動可有多張詢問單（餐點店 + 飲料店），所以比較的是合計，不是單張。
class EventBudget
  # :no_headcount 尚無人數 / :empty 還沒有詢問單 / :over 超出預算（紅字）/
  # :pending 外送費未知，合計待確認 / :room 低於 NT$80 × 人數（還有餘裕）/ :ok 正常
  attr_reader :event, :inquiries

  def initialize(event, inquiries: event.order_inquiries.to_a)
    @event = event
    @inquiries = inquiries
  end

  def headcount = event.headcount

  def total_budget = event.total_budget

  def min_budget = event.min_budget

  # 本場合計；只要有一張外送費未知就是 nil（待確認）
  def total
    return if pending?

    inquiries.sum(&:total)
  end

  # 已知部分的金額（小計 + 已知外送費）。即使有外送費未知，若已超出預算仍可判定超出。
  def known_total
    inquiries.sum { |inquiry| inquiry.subtotal + inquiry.delivery_fee.to_i }
  end

  def pending? = inquiries.any? { |inquiry| inquiry.total.nil? }

  # 預算還剩多少（以已知金額計算）；沒有人數時為 nil
  def remaining = total_budget && total_budget - known_total

  def status
    return :no_headcount if headcount.nil?
    return :empty if inquiries.empty?
    return :over if known_total > total_budget
    return :pending if pending?
    return :room if total < min_budget

    :ok
  end
end
