# 店家類型標籤：餐＋飲（accent）/ 只有餐 / 僅飲料（secondary）。kind 來自 Merchant#kind。
class KindBadgeComponent < ViewComponent::Base
  STYLES = {
    food_and_drink: "badge-accent",
    food_only: "badge-ghost",
    drink_only: "badge-secondary"
  }.freeze

  def initialize(kind:)
    @kind = kind.to_sym
  end

  def label = I18n.t("merchant_kind.#{@kind}")

  def css_class = STYLES.fetch(@kind)
end
