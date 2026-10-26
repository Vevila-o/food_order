require "test_helper"

class OrderPricingTest < ActiveSupport::TestCase
  test "預計金額 = Σ(單價 × 數量) + 外送費" do
    merchant = build(:merchant, delivery_fee: 60)

    result = OrderPricing.call(merchant: merchant, lines: [ [ 90, 18 ], [ 30, 18 ] ])

    assert_equal 2160, result.subtotal
    assert_equal 60, result.delivery_fee
    assert_equal 2220, result.total
  end

  test "外送費未知時外送費與預計金額都是 nil，不當 0" do
    merchant = build(:merchant, delivery_fee: nil)

    result = OrderPricing.call(merchant: merchant, lines: [ [ 90, 18 ] ])

    assert_equal 1620, result.subtotal
    assert_nil result.delivery_fee
    assert_nil result.total
  end

  test "外送費明確為 0 時預計金額等於小計" do
    result = OrderPricing.call(merchant: build(:merchant, delivery_fee: 0), lines: [ [ 90, 18 ] ])

    assert_equal 0, result.delivery_fee
    assert_equal 1620, result.total
  end

  test "滿額免運：小計達門檻時外送費為 0" do
    merchant = build(:merchant, delivery_fee: 60, free_delivery_threshold: 1500)

    result = OrderPricing.call(merchant: merchant, lines: [ [ 90, 18 ] ])

    assert_equal 0, result.delivery_fee
    assert_equal 1620, result.total
  end

  test "剛好達到門檻算免運，差一元則要外送費" do
    merchant = build(:merchant, delivery_fee: 60, free_delivery_threshold: 1620)

    assert_equal 0, OrderPricing.call(merchant: merchant, lines: [ [ 90, 18 ] ]).delivery_fee
    assert_equal 60, OrderPricing.call(merchant: merchant, lines: [ [ 89, 18 ] ]).delivery_fee
  end

  test "平常外送費未知，但達到免運門檻時外送費確定為 0" do
    merchant = build(:merchant, delivery_fee: nil, free_delivery_threshold: 1500)

    assert_equal 0, OrderPricing.call(merchant: merchant, lines: [ [ 90, 18 ] ]).delivery_fee
    assert_nil OrderPricing.call(merchant: merchant, lines: [ [ 50, 10 ] ]).delivery_fee
  end

  test "沒有任何品項時小計為 0" do
    assert_equal 0, OrderPricing.call(merchant: build(:merchant, delivery_fee: 0), lines: []).subtotal
  end
end
