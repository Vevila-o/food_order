class PriceEstimateComponentPreview < ViewComponent::Preview
  # 手填估價（優先）
  def manual
    render PriceEstimateComponent.new(merchant: PreviewMerchants.build(price_per_person_min: 80, price_per_person_max: 100))
  end

  # 沒手填：用新鮮菜單推算（最便宜餐食 + 最便宜飲料）
  def from_menu
    render PriceEstimateComponent.new(merchant: PreviewMerchants.build(offers_drink: true, menu: PreviewMerchants.fresh_menu))
  end

  # 只賣飲料：顯示單價 / 單位
  def drink_only_bulk
    merchant = PreviewMerchants.build(
      offers_food: false, offers_drink: true,
      menu: [ { name: "冬瓜茶（一桶）", category: "drink", price: 280, unit: "桶", servings: 20, menu_date: Date.current - 5 } ]
    )
    render PriceEstimateComponent.new(merchant: merchant)
  end

  # 菜單過期或沒填：估價未填
  def unknown
    render PriceEstimateComponent.new(merchant: PreviewMerchants.build(menu: PreviewMerchants.stale_menu))
  end
end
