class BackLinkComponentPreview < ViewComponent::Preview
  def default
    render BackLinkComponent.new(label: "返回列表", href: "/")
  end
end
