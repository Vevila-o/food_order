# 菜單新鮮度標籤：有效 / 菜單可能過期 / 日期不明。freshness 來自 MenuItem#freshness、Merchant#menu_freshness。
class FreshnessBadgeComponent < ViewComponent::Base
  def initialize(freshness:)
    @freshness = freshness.to_sym
  end

  def label = I18n.t("menu_freshness.#{@freshness}")

  # 有效用低調的一般色；過期與日期不明要醒目（設計稿用 secondary 的「待確認」色）
  def tone = @freshness == :fresh ? :base : :secondary
end
