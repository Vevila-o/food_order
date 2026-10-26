# 產生器的金額區：這張詢問單的小計 + 外送費 = 預計金額，以及本場合計與總預算的比較。
# 一場活動可有多張詢問單（餐點店 + 飲料店），預算比較的是合計。外送費未知（nil）顯示「待確認」，不當 0。
class BudgetSummaryComponent < ViewComponent::Base
  # pricing：OrderPricing::Result；budget：EventBudget（含這張試算）；others：本場其他店家的詢問單；any_lines：有沒有選品項
  def initialize(pricing:, budget:, others: [], any_lines: true)
    @pricing = pricing
    @budget = budget
    @others = others
    @any_lines = any_lines
  end

  attr_reader :pricing, :budget, :others

  def any_lines? = @any_lines

  def subtotal_text = helpers.format_money(pricing.subtotal)

  def fee_text
    case pricing.delivery_fee
    when nil then "待確認（未計入）"
    when 0 then "免外送費"
    else helpers.format_money(pricing.delivery_fee)
    end
  end

  def total_text
    return "—" unless any_lines?

    pricing.total ? helpers.format_money(pricing.total) : "待確認（不含外送費）"
  end

  def total_budget_text = helpers.format_money(budget.total_budget)

  # 本場合計：有外送費未知時只知道「至少」多少
  def event_total_text
    return helpers.format_money(budget.total) unless budget.pending?

    "至少 #{helpers.format_money(budget.known_total)}"
  end

  # [Pill 色調, 文字]
  def status
    return [ :base, "尚未選餐點" ] unless any_lines?

    case budget.status
    when :over then [ :warning, "超出預算 #{helpers.format_money(budget.known_total - budget.total_budget)}" ]
    when :pending then [ :secondary, "外送費待確認，合計尚未完整" ]
    when :room then [ :soft, "還有餘裕（低於 NT$#{Event::MIN_PER_PERSON} × 人數）" ]
    else [ :primary, "在預算內" ]
    end
  end
end
