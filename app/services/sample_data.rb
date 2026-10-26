# 開發用的範例資料。由 Maintenance Tasks 呼叫（/tasks），不放 db/seeds.rb。
#
# - 店家名稱一律以「【範例】」開頭，避免和真實店家混在一起，也方便一次移除。
# - 只允許在非正式環境執行。
# - 可重複執行：已存在的店家不會重複建立。
class SampleData
  PREFIX = "【範例】".freeze

  class ProductionError < StandardError; end

  def self.create!
    new.create!
  end

  def self.remove!
    new.remove!
  end

  def create!
    guard_production!
    created = Merchant.transaction do
      merchants = merchant_definitions.map { |attrs| create_merchant(attrs) }.compact
      create_event
      AppSetting.instance
      merchants
    end
    created.size
  end

  def remove!
    guard_production!
    Merchant.transaction do
      merchants = Merchant.where("name LIKE ?", "#{PREFIX}%")
      OrderInquiry.where(merchant: merchants).destroy_all
      OrderRecord.where(merchant: merchants).destroy_all
      Event.where("title LIKE ?", "#{PREFIX}%").destroy_all
      merchants.destroy_all.size
    end
  end

  private

  def guard_production!
    raise ProductionError, "範例資料不可在正式環境執行" if Rails.env.production?
  end

  # 已存在則略過（回傳 nil），否則建立店家與菜單並回傳店家
  def create_merchant(attrs)
    return if Merchant.exists?(name: attrs[:name])

    menu = attrs.delete(:menu)
    ordered_on = attrs.delete(:ordered_on)
    merchant = Merchant.create!(attrs)
    menu.each { |item| merchant.menu_items.create!(item) }
    merchant.order_records.create!(source: :manual, ordered_on: ordered_on) if ordered_on
    merchant
  end

  def create_event
    held_on = Date.current.next_occurring(:tuesday)
    return if Event.exists?(kktix_slug: Event.slug_for(held_on))

    event = Event.create!(held_on: held_on, title: "#{PREFIX}Ruby Jam #{held_on.year} 年 #{held_on.month} 月")
    event.registration_snapshots.create!(headcount: 18, source: :manual)
  end

  def merchant_definitions
    today = Date.current
    [
      {
        name: "#{PREFIX}阿嬤便當", address: "台北市大安區和平東路二段 1 號", district: "大安區",
        lat: 25.0450, lng: 121.5560, phone: "02-2700-0001", line_id: "@amabento",
        offers_food: true, offers_drink: false, delivers_at_19: "yes", delivers_to_daan: "yes",
        delivery_fee: 0, price_per_person_min: 80, price_per_person_max: 100, favorited: true,
        ordered_on: today << 2, # 兩個月前訂過
        menu: [
          { name: "雞腿飯", category: :food, price: 90, menu_date: today - 10 },
          { name: "排骨飯", category: :food, price: 85, menu_date: today - 10 },
          { name: "控肉飯（舊菜單）", category: :food, price: 80, menu_date: today - 130 }
        ]
      },
      {
        name: "#{PREFIX}綠光輕食", address: "台北市大安區復興南路二段 2 號", district: "大安區",
        lat: 25.0420, lng: 121.5440, instagram: "greenlight.food", messenger_id: "greenlight.food",
        offers_food: true, offers_drink: true, delivers_at_19: "unknown", delivers_to_daan: "yes",
        delivery_fee: 60, free_delivery_threshold: 1500, price_per_person_min: 90, price_per_person_max: 110,
        shortlisted: true, shortlist_position: 1, shortlist_note: "上次反應不錯，想再問 19:00 能不能送",
        menu: [
          { name: "雞肉沙拉", category: :food, price: 95, menu_date: today - 20 },
          { name: "檸檬紅茶", category: :drink, price: 35, menu_date: today - 20 }
        ]
      },
      {
        # 只賣飲料：整箱、整桶，用單位與可供幾人計算
        name: "#{PREFIX}大安涼飲批發", address: "台北市大安區新生南路一段 3 號", district: "大安區",
        lat: 25.0380, lng: 121.5330, phone: "02-2700-0003",
        offers_food: false, offers_drink: true, delivers_at_19: "yes", delivers_to_daan: "yes",
        menu: [
          { name: "鋁箔包紅茶（一箱 24 入）", category: :drink, price: 360, unit: "箱", servings: 24, menu_date: today - 15 },
          { name: "冬瓜茶（一桶）", category: :drink, price: 280, unit: "桶", servings: 20, menu_date: today - 15 }
        ]
      },
      {
        # 19:00 明確不可外送、沒有任何聯絡方式、菜單日期不明
        name: "#{PREFIX}深夜滷味", address: "台北市大安區師大路 4 號", district: "大安區",
        offers_food: true, offers_drink: false, delivers_at_19: "no", delivers_to_daan: "yes",
        menu: [
          { name: "綜合滷味", category: :food, price: 100, menu_date: nil }
        ]
      },
      {
        # 外區但可送大安區
        name: "#{PREFIX}公館義大利麵", address: "台北市中正區羅斯福路三段 5 號", district: "中正區",
        lat: 25.0150, lng: 121.5330, instagram: "pasta.gongguan",
        offers_food: true, offers_drink: false, delivers_at_19: "unknown", delivers_to_daan: "yes",
        delivery_fee: 80, price_per_person_min: 110, price_per_person_max: 130,
        menu: [
          { name: "奶油培根義大利麵", category: :food, price: 120, menu_date: today - 30 }
        ]
      }
    ]
  end
end
