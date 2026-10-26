# 單張詢問單的金額：小計 + 外送費 = 預計金額。
#
# 外送費未知（NULL）時，外送費與預計金額都是 nil，介面顯示「待確認」，絕不當 0 算。
# 滿額免運：小計達到 free_delivery_threshold 時外送費為 0（即使平常的外送費未知）。
class OrderPricing
  Result = Data.define(:subtotal, :delivery_fee, :total)

  # lines: [[單價, 數量], ...]；單價一律由伺服器端的 menu_items.price 帶入，不信任前端傳值
  def self.call(merchant:, lines:)
    subtotal = lines.sum { |unit_price, quantity| unit_price * quantity }
    fee = delivery_fee_for(merchant, subtotal)
    Result.new(subtotal: subtotal, delivery_fee: fee, total: fee && subtotal + fee)
  end

  def self.delivery_fee_for(merchant, subtotal)
    threshold = merchant.free_delivery_threshold
    return 0 if threshold && subtotal >= threshold

    merchant.delivery_fee
  end
end
