# 店家類型標籤：餐＋飲（accent 強調）/ 只有餐（soft）/ 僅飲料（secondary）。kind 來自 Merchant#kind。
class KindBadgeComponent < ViewComponent::Base
  TONES = { food_and_drink: :accent, food_only: :soft, drink_only: :secondary }.freeze

  def initialize(kind:)
    @kind = kind.to_sym
  end

  def label = I18n.t("merchant_kind.#{@kind}")

  def tone = TONES.fetch(@kind)
end
