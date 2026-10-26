class FilterBarComponentPreview < ViewComponent::Preview
  # 沒有任何條件。膠囊勾選就自動套用；「更多篩選」開底部抽屜（桌機是置中視窗）。
  def default
    render FilterBarComponent.new(filter: MerchantFilter.new({}))
  end

  # 設計稿的預設狀態：餐＋飲、19:00 可外送、菜單 4 個月內
  def design_default
    filter = MerchantFilter.new({ kinds: [ "food_and_drink" ], delivers_at_19: "1", fresh_menu: "1" })
    render FilterBarComponent.new(filter: filter)
  end

  # 抽屜裡也有條件：「更多篩選」按鈕會顯示數量
  def with_drawer_filters
    filter = MerchantFilter.new({ kinds: %w[food_and_drink drink_only], daan: "1", never_ordered: "1", sort: "price" })
    render FilterBarComponent.new(filter: filter)
  end
end
