# 產生器的金額區：這張詢問單的小計 + 外送費 = 預計金額，以及本場合計與總預算的比較。
# 一場活動可有多張詢問單（餐點店 + 飲料店），預算比較的是合計。外送費未知（nil）顯示「待確認」，不當 0。
# 配對兩家時，pricing 是兩家的合計，parts 列出各家的明細。
class BudgetSummaryComponent < ViewComponent::Base
  # 某一家的明細：店名與它的 OrderPricing::Result
  Part = Data.define(:name, :pricing)

  # pricing：小計 / 外送費 / 預計金額（單店是 OrderPricing::Result，兩家是合計）；budget：EventBudget（含試算）；
  # any_lines：有沒有選品項；parts：兩家都有選時各家的明細（單店不用給）
  def initialize(pricing:, budget:, any_lines: true, parts: [])
    @pricing = pricing
    @budget = budget
    @any_lines = any_lines
    @parts = parts
  end

  attr_reader :pricing, :budget, :parts

  def show_parts? = parts.size > 1

  def part_fee_text(part)
    case part.pricing.delivery_fee
    when nil then "外送費待確認"
    when 0 then "免外送費"
    else "外送費 #{helpers.format_money(part.pricing.delivery_fee)}"
    end
  end

  def part_total_text(part) = part.pricing.total ? helpers.format_money(part.pricing.total) : "—"

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
