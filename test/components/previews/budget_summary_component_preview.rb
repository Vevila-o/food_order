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

  # 本場還有其他店家（餐點店 + 飲料店）：合計含其他店
  def with_other_merchants
    others = [ inquiry("【範例】大安涼飲批發", subtotal: 560, fee: 0), inquiry("【範例】公館義大利麵", subtotal: 400, fee: nil) ]
    render_summary(subtotal: 700, fee: 60, others: others)
  end

  # 還沒選餐點
  def nothing_selected
    render_summary(subtotal: 0, fee: 60, any_lines: false)
  end

  private

  def render_summary(subtotal:, fee:, others: [], any_lines: true)
    merchant = PreviewMerchants.build(delivery_fee: fee)
    pricing = OrderPricing::Result.new(subtotal: subtotal, delivery_fee: fee, total: fee && subtotal + fee)
    event = Event.new(held_on: Date.current.next_occurring(:tuesday))
    event.define_singleton_method(:headcount) { 18 }
    mine = OrderInquiry.new(merchant: merchant, subtotal: subtotal, delivery_fee: fee, total: pricing.total, headcount_at_creation: 18)
    render BudgetSummaryComponent.new(pricing: pricing, budget: EventBudget.new(event, inquiries: others + [ mine ]), others: others, any_lines: any_lines)
  end

  def inquiry(name, subtotal:, fee:)
    OrderInquiry.new(merchant: PreviewMerchants.build(name: name), subtotal: subtotal, delivery_fee: fee, total: fee && subtotal + fee, headcount_at_creation: 18)
  end
end
