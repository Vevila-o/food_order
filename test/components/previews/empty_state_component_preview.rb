class EmptyStateComponentPreview < ViewComponent::Preview
  def default
    render(EmptyStateComponent.new(title: "還沒有店家")) { "可以先新增一間店家。" }
  end

  def with_action
    render(EmptyStateComponent.new(title: "沒有符合條件的店家")) do |empty|
      empty.with_action { tag.a("清除篩選", href: "#", class: "btn btn-primary") }
      "試著放寬條件。"
    end
  end
end
