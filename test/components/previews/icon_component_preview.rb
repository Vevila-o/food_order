class IconComponentPreview < ViewComponent::Preview
  # 圖示都是裝飾用（aria-hidden）。填色用 Tailwind 的 fill class。
  # @param name select [plus, chevron_left, external, star, bookmark]
  # @param size number
  def playground(name: "star", size: 24)
    render IconComponent.new(name: name, size: size.to_i)
  end

  def all_icons
    render_with_template
  end

  def filled_star
    render IconComponent.new(name: :star, size: 28, class: "fill-accent")
  end
end
