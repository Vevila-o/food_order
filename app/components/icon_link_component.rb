# 圓形圖示連結（例如首頁的「＋ 新增店家」）。只有圖示，所以 label 一定要給（成為 aria-label）。
# show_label: true 時，桌機（md 以上）圖示旁多顯示文字，變成膠囊；手機仍是只有圖示的圓形（空間小）。
class IconLinkComponent < ViewComponent::Base
  VARIANTS = { primary: "btn-primary", plain: "bg-base-200 border-0" }.freeze

  def initialize(icon:, label:, href:, variant: :primary, show_label: false)
    @icon = icon
    @label = label
    @href = href
    @variant = variant.to_sym
    @show_label = show_label
  end

  attr_reader :label, :href

  def show_label? = @show_label

  def css_class
    base = "btn btn-circle size-11 #{VARIANTS.fetch(@variant)}"
    show_label? ? "#{base} md:h-11 md:w-auto md:gap-2 md:px-4" : base
  end
end
