# 收藏（星號）/ 下次候選（書籤）的切換按鈕（設計稿）：44px 圓形，按下後換色並填色圖示。
# 是一個送出 POST（加入）或 DELETE（移除）的表單，Turbo 只替換這顆按鈕。
# 狀態用 aria-pressed 表達，aria-label 固定（讀屏會唸「收藏，已按下」）。
class ToggleButtonComponent < ViewComponent::Base
  KINDS = {
    favorite: { label: "收藏", icon: :star, field: :favorited, route: :merchant_favorite_path, on_bg: "bg-accent-soft", on_icon: "fill-accent" },
    shortlist: { label: "下次候選", icon: :bookmark, field: :shortlisted, route: :merchant_shortlist_path, on_bg: "bg-warning-soft", on_icon: "fill-warning" }
  }.freeze

  # Turbo Stream 用這個 id 找到要替換的表單
  def self.dom_id_for(merchant, kind) = "#{kind}_merchant_#{merchant.id}"

  def initialize(merchant:, kind:)
    @merchant = merchant
    @kind = kind.to_sym
    @config = KINDS.fetch(@kind)
  end

  attr_reader :merchant

  def label = @config[:label]

  def pressed? = merchant.public_send(@config[:field])

  def dom_id = self.class.dom_id_for(merchant, @kind)

  def path = helpers.public_send(@config[:route], merchant)

  # 已按下就送 DELETE（移除），否則 POST（加入）
  def http_method = pressed? ? :delete : :post

  def button_class
    background = pressed? ? @config[:on_bg] : "bg-base-200"
    "inline-flex size-11 cursor-pointer items-center justify-center rounded-full text-base-content focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-base-content #{background}"
  end

  def icon = render(IconComponent.new(name: @config[:icon], size: 20, class: (@config[:on_icon] if pressed?)))
end
