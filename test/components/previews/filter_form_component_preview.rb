class FilterFormComponentPreview < ViewComponent::Preview
  # 桌機左側欄：勾選就自動套用
  def sidebar
    render FilterFormComponent.new(filter: MerchantFilter.new({}), variant: :sidebar)
  end

  # 手機底部抽屜：按「套用」才篩選
  def drawer
    render FilterFormComponent.new(filter: MerchantFilter.new({}), variant: :drawer)
  end

  # 已有條件：勾選狀態、排序與「清除篩選」
  def with_active_filters
    filter = MerchantFilter.new({ kind: "food_only", free_delivery: "1", favorited: "1", sort: "price" })
    render FilterFormComponent.new(filter: filter, variant: :sidebar)
  end
end
