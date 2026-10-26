class OrderedDotComponentPreview < ViewComponent::Preview
  # 「曾訂購」圓點：橘色 = 曾訂購、灰色 = 沒訂過（旁邊一定有文字）。
  # @param ordered toggle
  def playground(ordered: true)
    render OrderedDotComponent.new(ordered: ordered)
  end

  def ordered = render(OrderedDotComponent.new(ordered: true))

  def never_ordered = render(OrderedDotComponent.new(ordered: false))
end
