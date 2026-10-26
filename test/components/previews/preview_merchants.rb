# 元件預覽用的假資料：只在記憶體中建立（Merchant.new），不寫入資料庫。
module PreviewMerchants
  module_function

  # 不會對應到任何真實資料列的假 id，讓卡片能產生 /merchants/:id 連結
  PREVIEW_ID = 2_000_000_000

  def build(name: "【範例】阿嬤便當", ordered: false, menu: [], **attrs)
    Merchant.new({ name: name, offers_food: true }.merge(attrs)).tap do |merchant|
      merchant.id = PREVIEW_ID
      # 看起來像已存在的紀錄（有 to_param），但仍是記憶體物件，關聯不會查資料庫
      merchant.define_singleton_method(:persisted?) { true }
      menu.each { |item| merchant.menu_items.build(item) }
      merchant.order_records.build(source: :manual, ordered_on: Date.current - 60) if ordered
    end
  end

  def fresh_menu
    today = Date.current
    [
      { name: "雞腿飯", category: "food", price: 90, menu_date: today - 10 },
      { name: "紅茶", category: "drink", price: 30, menu_date: today - 10 }
    ]
  end

  def stale_menu
    [ { name: "控肉飯", category: "food", price: 80, menu_date: Date.current - 130 } ]
  end
end
