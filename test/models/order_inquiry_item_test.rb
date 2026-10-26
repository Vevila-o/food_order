require "test_helper"

class OrderInquiryItemTest < ActiveSupport::TestCase
  test "小計 = 單價 × 數量" do
    assert_equal 1620, build(:order_inquiry_item, unit_price: 90, quantity: 18).line_total
  end

  test "數量必須大於 0，單價不可為負" do
    assert_not build(:order_inquiry_item, quantity: 0).valid?
    assert_not build(:order_inquiry_item, unit_price: -1).valid?
  end

  test "名稱必填" do
    assert_not build(:order_inquiry_item, name: "").valid?
  end
end
