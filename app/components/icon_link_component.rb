# 圓形圖示連結（例如首頁的「＋ 新增店家」）。只有圖示，所以 label 一定要給（成為 aria-label）。
class IconLinkComponent < ViewComponent::Base
  VARIANTS = { primary: "btn-primary", plain: "bg-base-200 border-0" }.freeze

  def initialize(icon:, label:, href:, variant: :primary)
    @icon = icon
    @label = label
    @href = href
    @variant = variant.to_sym
  end

  def css_class = "btn btn-circle size-11 #{VARIANTS.fetch(@variant)}"
end
