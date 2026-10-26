class FreshnessBadgeComponentPreview < ViewComponent::Preview
  # 菜單新鮮度。超過 120 天顯示「菜單可能過期」，日期不明也要醒目。
  # @param freshness select [fresh, stale, unknown]
  def playground(freshness: "stale")
    render FreshnessBadgeComponent.new(freshness: freshness)
  end

  def fresh = render(FreshnessBadgeComponent.new(freshness: :fresh))

  def stale = render(FreshnessBadgeComponent.new(freshness: :stale))

  def unknown = render(FreshnessBadgeComponent.new(freshness: :unknown))
end
