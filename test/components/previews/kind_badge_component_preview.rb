class KindBadgeComponentPreview < ViewComponent::Preview
  # 店家類型標籤。餐＋飲用 accent 色票，僅飲料用 secondary。
  # @param kind select [food_and_drink, food_only, drink_only]
  def playground(kind: "food_and_drink")
    render KindBadgeComponent.new(kind: kind)
  end

  def food_and_drink = render(KindBadgeComponent.new(kind: :food_and_drink))

  def food_only = render(KindBadgeComponent.new(kind: :food_only))

  def drink_only = render(KindBadgeComponent.new(kind: :drink_only))
end
