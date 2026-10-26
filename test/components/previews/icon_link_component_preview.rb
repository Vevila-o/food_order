class IconLinkComponentPreview < ViewComponent::Preview
  def primary
    render IconLinkComponent.new(icon: :plus, label: "新增店家", href: "/merchants/new")
  end

  def plain
    render IconLinkComponent.new(icon: :plus, label: "新增店家", href: "/merchants/new", variant: :plain)
  end
end
