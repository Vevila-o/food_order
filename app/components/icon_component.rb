# 內嵌 SVG 圖示（stroke 用 currentColor，跟著文字色）。圖示都是裝飾（aria-hidden），
# 單獨出現的圖示按鈕要在外層加 aria-label（見 IconLinkComponent）。
# 要填色（例如已收藏的星號）用 Tailwind 的 fill class：IconComponent.new(name: :star, class: "fill-accent")
class IconComponent < ViewComponent::Base
  PATHS = {
    plus: "M12 5v14M5 12h14",
    chevron_left: "M15 5l-7 7 7 7",
    external: "M7 17L17 7M8 7h9v9",
    star: "M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z",
    bookmark: "M6.5 3.5h11v17l-5.5-4-5.5 4z",
    menu: "M4 6h16M4 12h16M4 18h16",
    close: "M6 6l12 12M18 6L6 18",
    home: "M3 10l9-7 9 7v10a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z",
    history: "M12 7v5l3 2M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z",
    message: "M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z",
    check_circle: "M9 12l2 2 4-4M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z"
  }.freeze

  def initialize(name:, size: 20, **options)
    @name = name.to_sym
    @size = size
    @options = options
  end

  def path = PATHS.fetch(@name)

  def svg_options
    { width: @size, height: @size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.8,
      "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": "true" }.merge(@options)
  end
end
