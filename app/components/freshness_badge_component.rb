# 菜單新鮮度標籤：有效 / 菜單可能過期 / 日期不明。freshness 來自 MenuItem#freshness、Merchant#menu_freshness。
class FreshnessBadgeComponent < ViewComponent::Base
  def initialize(freshness:)
    @freshness = freshness.to_sym
  end

  def label = I18n.t("menu_freshness.#{@freshness}")

  # 有效用低調的 ghost；過期與日期不明要醒目（warning）
  def css_class = @freshness == :fresh ? "badge-ghost" : "badge-warning"
end
