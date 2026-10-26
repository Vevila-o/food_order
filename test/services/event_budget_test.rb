require "test_helper"

class EventBudgetTest < ActiveSupport::TestCase
  setup { @event = create(:event, :with_headcount, headcount: 18) } # 總預算 1800，下限 1440

  def budget = EventBudget.new(@event.reload)

  def add_inquiry(*traits, **attrs)
    create(:order_inquiry, *traits, event: @event, **attrs)
  end

  test "尚無人數" do
    event = create(:event, held_on: Date.new(2026, 11, 17))

    assert_equal :no_headcount, EventBudget.new(event).status
  end

  test "還沒有詢問單" do
    assert_equal :empty, budget.status
  end

  test "合計在預算內且不低於下限：正常" do
    add_inquiry(subtotal: 1700, delivery_fee: 0, total: 1700)

    assert_equal :ok, budget.status
    assert_equal 1700, budget.total
    assert_equal 100, budget.remaining
  end

  test "剛好等於預算仍算正常" do
    add_inquiry(subtotal: 1800, delivery_fee: 0, total: 1800)

    assert_equal :ok, budget.status
  end

  test "超過預算：紅字" do
    add_inquiry(subtotal: 1750, delivery_fee: 60, total: 1810)

    assert_equal :over, budget.status
  end

  test "低於 NT$80 × 人數：還有餘裕" do
    add_inquiry(subtotal: 1400, delivery_fee: 0, total: 1400)

    assert_equal :room, budget.status
  end

  test "餐點店 + 飲料店的合計一起和總預算比較" do
    add_inquiry(subtotal: 1260, delivery_fee: 0, total: 1260)
    add_inquiry(subtotal: 480, delivery_fee: 60, total: 540)

    assert_equal 1800, budget.total
    assert_equal :ok, budget.status
  end

  test "兩張單各自在預算內，合計卻超出" do
    add_inquiry(subtotal: 1200, delivery_fee: 0, total: 1200)
    add_inquiry(subtotal: 700, delivery_fee: 0, total: 700)

    assert_equal :over, budget.status
  end

  test "任一張外送費未知：合計待確認（nil），不當 0" do
    add_inquiry(subtotal: 1260, delivery_fee: 0, total: 1260)
    add_inquiry(:fee_unknown, subtotal: 300)

    assert_equal :pending, budget.status
    assert_nil budget.total
  end

  test "外送費未知但已知金額已超出預算，仍判定超出" do
    add_inquiry(subtotal: 1850, delivery_fee: 0, total: 1850)
    add_inquiry(:fee_unknown, subtotal: 100)

    assert_equal :over, budget.status
  end

  test "剩餘預算以已知金額計算" do
    add_inquiry(subtotal: 1260, delivery_fee: 0, total: 1260)
    add_inquiry(:fee_unknown, subtotal: 300)

    assert_equal 240, budget.remaining
  end
end
