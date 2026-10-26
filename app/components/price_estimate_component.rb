# 卡片上的「每人估價」（M2-b 決定）：
#   手填 → 每人 NT$80–100；沒手填用菜單推算 → 每人約 NT$130（依菜單）；
#   只賣飲料 → NT$280 / 桶；都算不出來 → 估價未填。
class PriceEstimateComponent < ViewComponent::Base
  def initialize(merchant:)
    @merchant = merchant
  end

  def text
    if (estimate = @merchant.price_estimate)
      estimate_text(estimate)
    elsif (item = @merchant.bulk_drink_item)
      [ money(item.price), item.unit.presence ].compact.join(" / ")
    else
      "估價未填"
    end
  end

  # 估價未填時用較淡的字，提醒資料還不完整
  def css_class = text == "估價未填" ? "text-muted" : "font-medium"

  private

  def estimate_text(estimate)
    if estimate.source == :menu
      "每人約 #{money(estimate.min)}（依菜單）"
    elsif estimate.min == estimate.max
      "每人 #{money(estimate.min)}"
    else
      "每人 #{money(estimate.min)}–#{estimate.max}"
    end
  end

  def money(amount) = "NT$#{helpers.number_with_delimiter(amount)}"
end
