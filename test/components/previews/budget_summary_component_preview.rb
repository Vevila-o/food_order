class BudgetSummaryComponentPreview < ViewComponent::Preview
  # 在預算內：18 人，總預算 NT$1,800，這張 NT$1,620（滿額免運）
  def within_budget
    render_summary(subtotal: 1620, fee: 0)
  end

  # 低於 NT$80 × 人數：還有餘裕
  def room
    render_summary(subtotal: 900, fee: 60)
  end

  # 超出預算：顯示超出多少
  def over_budget
    render_summary(subtotal: 2160, fee: 0)
  end

  # 外送費未知：預計金額「待確認」、合計「至少」，不當 0
  def fee_unknown
    render_summary(subtotal: 1500, fee: nil)
  end

  # 還沒選餐點
  def nothing_selected
    render_summary(subtotal: 0, fee: 60, any_lines: false)
  end

  private

  def render_summary(subtotal:, fee:, any_lines: true)
    merchant = PreviewMerchants.build(delivery_fee: fee)
    pricing = OrderPricing::Result.new(subtotal: subtotal, delivery_fee: fee, total: fee && subtotal + fee)
    event = Event.new(held_on: Date.current.next_occurring(:tuesday))
    event.define_singleton_method(:headcount) { 18 }
    mine = OrderInquiry.new(merchant: merchant, subtotal: subtotal, delivery_fee: fee, total: pricing.total, headcount_at_creation: 18)
    render BudgetSummaryComponent.new(pricing: pricing, budget: EventBudget.new(event, inquiries: [ mine ]), any_lines: any_lines)
  end
end
