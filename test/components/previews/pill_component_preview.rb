class PillComponentPreview < ViewComponent::Preview
  # @param tone select [base, accent, soft, secondary, warning]
  def playground(tone: "accent")
    render(PillComponent.new(tone: tone)) { "餐＋飲" }
  end

  def all_tones
    render_with_template
  end
end
