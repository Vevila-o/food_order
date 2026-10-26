class PartnerPickCardComponentPreview < ViewComponent::Preview
  # 一般：菜單有效，可以選
  def default
    render PartnerPickCardComponent.new(merchant: PreviewMerchants.build(name: "【範例】大安涼飲批發", offers_food: false, offers_drink: true, delivers_at_19: "yes",
                                                                         delivery_fee: 50, menu: PreviewMerchants.fresh_menu))
  end

  # 已選：按鈕停用，卡片外框強調
  def selected
    render PartnerPickCardComponent.new(merchant: PreviewMerchants.build(menu: PreviewMerchants.fresh_menu, delivery_fee: 0), selected: true)
  end

  # 菜單全部過期：照列，但不能選
  def stale_menu
    render PartnerPickCardComponent.new(merchant: PreviewMerchants.build(name: "【範例】公館義大利麵", menu: PreviewMerchants.stale_menu))
  end

  # 這場活動已有這間店的詢問單
  def inquired
    render PartnerPickCardComponent.new(merchant: PreviewMerchants.build(menu: PreviewMerchants.fresh_menu, delivery_fee: 60), inquired: true)
  end

  # 外送費、19:00 外送未知：用「待確認」標籤
  def unknown_fee
    render PartnerPickCardComponent.new(merchant: PreviewMerchants.build(menu: PreviewMerchants.fresh_menu))
  end
end
