class MerchantCardComponentPreview < ViewComponent::Preview
  # 一般店家：餐＋飲、曾訂購
  def default
    merchant = PreviewMerchants.build(
      ordered: true, offers_drink: true, delivers_at_19: "yes", delivery_fee: 0,
      address: "台北市大安區和平東路二段 1 號", lat: 25.0450, lng: 121.5560,
      menu: PreviewMerchants.fresh_menu
    )
    render MerchantCardComponent.new(merchant: merchant)
  end

  # 只賣飲料（整桶）：沒有每人估價，顯示單價 / 單位
  # 最近 45 天內訂過：曾訂購圓點旁多一個「上次剛訂過」標籤（避免連續兩個月訂同一家）
  def recently_ordered
    merchant = PreviewMerchants.build(menu: PreviewMerchants.fresh_menu, delivers_at_19: "yes", delivery_fee: 0)
    merchant.order_records.build(source: :manual, ordered_on: Date.current - 12)
    render MerchantCardComponent.new(merchant: merchant)
  end

  def drink_only
    merchant = PreviewMerchants.build(
      name: "【範例】大安涼飲批發", offers_food: false, offers_drink: true, delivers_at_19: "yes",
      menu: [ { name: "冬瓜茶（一桶）", category: "drink", price: 280, unit: "桶", servings: 20, menu_date: Date.current - 5 } ]
    )
    render MerchantCardComponent.new(merchant: merchant)
  end

  # 資料不完整：外送費未知（顯示「待確認」而不是 0）、菜單過期、沒有座標
  def incomplete
    merchant = PreviewMerchants.build(name: "【範例】深夜滷味", delivers_at_19: "no", menu: PreviewMerchants.stale_menu)
    render MerchantCardComponent.new(merchant: merchant)
  end

  # 滿額免運
  def free_delivery_threshold
    merchant = PreviewMerchants.build(delivery_fee: 60, free_delivery_threshold: 1500, menu: PreviewMerchants.fresh_menu)
    render MerchantCardComponent.new(merchant: merchant)
  end

  # 已收藏 + 已加入候選：星號與書籤填色
  def favorited_and_shortlisted
    merchant = PreviewMerchants.build(favorited: true, shortlisted: true, menu: PreviewMerchants.fresh_menu)
    render MerchantCardComponent.new(merchant: merchant)
  end
end
