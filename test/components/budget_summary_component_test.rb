require "test_helper"

class BudgetSummaryComponentTest < ViewComponent::TestCase
  setup do
    @event = build(:event)
    @event.define_singleton_method(:headcount) { 18 }
  end

  def inquiry(subtotal:, fee:, merchant: build(:merchant, name: "其他店"))
    OrderInquiry.new(merchant: merchant, subtotal: subtotal, delivery_fee: fee, total: fee && subtotal + fee, headcount_at_creation: 18)
  end

  def render_summary(subtotal:, fee:, others: [], any_lines: true)
    pricing = OrderPricing::Result.new(subtotal: subtotal, delivery_fee: fee, total: fee && subtotal + fee)
    budget = EventBudget.new(@event, inquiries: others + [ inquiry(subtotal: subtotal, fee: fee) ])
    render_inline(BudgetSummaryComponent.new(pricing: pricing, budget: budget, others: others, any_lines: any_lines))
  end

  test "小計、外送費、預計金額與總預算（人數 × NT$100）" do
    render_summary(subtotal: 900, fee: 60)

    assert_selector "dd", text: "NT$900"
    assert_selector "dd", text: "NT$60"
    assert_selector "dd", text: "NT$960"
    assert_text "本場總預算（18 人 × NT$100）"
    assert_text "NT$1,800"
  end

  test "外送費 0：顯示免外送費" do
    render_summary(subtotal: 1620, fee: 0)

    assert_selector "dd", text: "免外送費"
  end

  test "外送費未知：顯示待確認，預計金額不當 0，合計標示至少" do
    render_summary(subtotal: 1500, fee: nil)

    assert_selector "dd", text: "待確認（未計入）"
    assert_selector "dd", text: "待確認（不含外送費）"
    assert_text "至少 NT$1,500"
    assert_no_text "NT$0"
    assert_selector "span.bg-secondary", text: "外送費待確認，合計尚未完整"
  end

  test "在預算內" do
    render_summary(subtotal: 1500, fee: 0)

    assert_selector "span.bg-primary", text: "在預算內"
  end

  test "低於 NT$80 × 人數：還有餘裕" do
    render_summary(subtotal: 900, fee: 60) # 960 < 1440

    assert_selector "span.bg-soft", text: "還有餘裕（低於 NT$80 × 人數）"
  end

  test "超出預算：warning 色並顯示超出多少" do
    render_summary(subtotal: 2160, fee: 0)

    assert_selector "span.bg-warning", text: "超出預算 NT$360"
  end

  test "外送費未知但已知部分就超出：仍判定超出" do
    render_summary(subtotal: 1900, fee: nil)

    assert_selector "span.bg-warning", text: "超出預算 NT$100"
  end

  test "本場其他店家：合計含其他店，列出各店金額" do
    others = [ inquiry(subtotal: 560, fee: 0, merchant: build(:merchant, name: "涼飲店")), inquiry(subtotal: 400, fee: nil, merchant: build(:merchant, name: "麵店")) ]

    render_summary(subtotal: 700, fee: 60, others: others)

    assert_text "本場合計（含其他店家）"
    assert_selector "li", text: /涼飲店\s+NT\$560/
    assert_selector "li", text: /麵店\s+外送費待確認/
  end

  test "沒有其他店家：不顯示清單與「含其他店家」" do
    render_summary(subtotal: 900, fee: 60)

    assert_no_selector "ul"
    assert_no_text "含其他店家"
  end

  test "還沒選餐點：預計金額顯示破折號、狀態是尚未選餐點" do
    render_summary(subtotal: 0, fee: 60, any_lines: false)

    assert_selector "dd", text: "—"
    assert_selector "span.bg-base-200", text: "尚未選餐點"
  end

  test "兩家配對：列出各家明細（小計、外送費、金額）" do
    parts = [
      BudgetSummaryComponent::Part.new(name: "便當店", pricing: OrderPricing::Result.new(subtotal: 900, delivery_fee: 60, total: 960)),
      BudgetSummaryComponent::Part.new(name: "涼飲店", pricing: OrderPricing::Result.new(subtotal: 600, delivery_fee: nil, total: nil)),
      BudgetSummaryComponent::Part.new(name: "免運店", pricing: OrderPricing::Result.new(subtotal: 100, delivery_fee: 0, total: 100))
    ]
    pricing = OrderPricing::Result.new(subtotal: 1600, delivery_fee: nil, total: nil)
    render_inline(BudgetSummaryComponent.new(pricing: pricing, budget: EventBudget.new(@event, inquiries: []), parts: parts))

    assert_selector "ul[aria-label='各店明細'] li", count: 3
    assert_selector "li", text: /便當店\s+小計 NT\$900 · 外送費 NT\$60 · NT\$960/
    assert_selector "li", text: /涼飲店\s+小計 NT\$600 · 外送費待確認 · —/
    assert_selector "li", text: /免運店.*免外送費/m
  end

  test "只有一家（或沒給 parts）：不顯示各店明細" do
    render_summary(subtotal: 900, fee: 60)

    assert_no_selector "ul[aria-label='各店明細']"
  end
end
