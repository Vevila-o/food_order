class Merchant < ApplicationRecord
  # PicCollage 公司總部（Cardinal Blue Software），距離計算的基準點
  PICCOLLAGE_LAT = 25.0433959
  PICCOLLAGE_LNG = 121.5574278
  EARTH_RADIUS_KM = 6371.0

  has_many :sources, class_name: "MerchantSource", dependent: :destroy
  has_many :menu_items, dependent: :destroy
  # 有詢問單 / 訂購紀錄的店家不可刪除，否則歷史會斷
  has_many :order_inquiries, dependent: :restrict_with_error
  has_many :order_records, dependent: :restrict_with_error

  # yes / no / unknown。prefix 避免出現 `yes?`、`no?` 這種怪方法名
  enum :delivers_at_19, { yes: "yes", no: "no", unknown: "unknown" }, prefix: true, validate: true
  enum :delivers_to_daan, { yes: "yes", no: "no", unknown: "unknown" }, prefix: true, validate: true

  # 菜單與來源在店家表單中一起編輯。完全空白的列（品名與價格都沒填）會被忽略。
  accepts_nested_attributes_for :menu_items, allow_destroy: true,
    reject_if: ->(attrs) { attrs.values_at("name", "price").all?(&:blank?) }
  accepts_nested_attributes_for :sources, allow_destroy: true,
    reject_if: ->(attrs) { attrs["url"].blank? }

  before_validation :normalize_contacts

  validates :name, presence: true
  validate :offers_food_or_drink
  validate :price_range_in_order
  validates :delivery_fee, :free_delivery_threshold, :price_per_person_min, :price_per_person_max,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :lat, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :lng, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :line_id, format: { with: /\A[@~][\w.\-]+\z/, message: "必須以 @（官方帳號）或 ~（個人 ID）開頭" }, allow_blank: true
  validates :threads, format: { with: /\A[\w.]+\z/, message: "只能包含英數字、底線與句點" }, allow_blank: true
  validates :instagram, format: { with: /\A[\w.]+\z/, message: "只能包含英數字、底線與句點" }, allow_blank: true
  validates :messenger_id, format: { with: /\A[\w.\-]+\z/, message: "只能包含英數字、底線、句點與連字號" }, allow_blank: true
  validates :phone, format: { with: /\A[\d+\-\s()#]+\z/, message: "只能包含數字與 + - ( ) 空白" }, allow_blank: true

  scope :favorited, -> { where(favorited: true) }
  scope :shortlisted, -> { where(shortlisted: true).order(:shortlist_position, :id) }
  scope :food_and_drink, -> { where(offers_food: true, offers_drink: true) }
  scope :food_only, -> { where(offers_food: true, offers_drink: false) }
  scope :drink_only, -> { where(offers_food: false, offers_drink: true) }
  # 「可 19:00 外送」：排除明確不可，待確認的也顯示（否則清單幾乎全空）
  scope :possibly_delivers_at_19, -> { where.not(delivers_at_19: "no") }
  scope :possibly_delivers_to_daan, -> { where.not(delivers_to_daan: "no") }
  # 「大安區內 / 可送大安區」：行政區是大安區，或沒有明確表示不能送大安區（外區店家待確認也顯示）
  scope :in_or_delivers_to_daan, -> { where(district: "大安區").or(possibly_delivers_to_daan) }
  # 菜單在 4 個月內：至少有一個新鮮的菜單項目
  scope :with_fresh_menu, -> { where(id: MenuItem.fresh.select(:merchant_id)) }
  scope :price_per_person_within, ->(limit) { where(price_per_person_min: ..limit) }
  scope :ordered_before, -> { where(id: OrderRecord.select(:merchant_id)) }
  scope :never_ordered, -> { where.not(id: OrderRecord.select(:merchant_id)) }

  # 免外送費：外送費明確為 0，或滿額免運且門檻不高於預算（budget 為 nil 時只看外送費 0）
  def self.free_delivery(budget = nil)
    scope = where(delivery_fee: 0)
    budget ? scope.or(where(free_delivery_threshold: ..budget)) : scope
  end

  def kind
    if offers_food && offers_drink then :food_and_drink
    elsif offers_food then :food_only
    else :drink_only
    end
  end

  def drink_only? = kind == :drink_only

  # 「曾訂購」圓點是衍生值，不是欄位：避免按鈕狀態與紀錄兩個真相不一致。
  # 列表頁請 includes(:order_records)，避免 N+1。
  def ordered_before? = order_records.any?

  # 到 PicCollage 的直線距離（公里）；沒有座標時為 nil
  def distance_km
    return if lat.nil? || lng.nil?

    rad = ->(deg) { deg.to_f * Math::PI / 180 }
    d_lat = rad.(lat) - rad.(PICCOLLAGE_LAT)
    d_lng = rad.(lng) - rad.(PICCOLLAGE_LNG)
    a = Math.sin(d_lat / 2)**2 + Math.cos(rad.(PICCOLLAGE_LAT)) * Math.cos(rad.(lat)) * Math.sin(d_lng / 2)**2
    (EARTH_RADIUS_KM * 2 * Math.asin(Math.sqrt(a))).round(2)
  end

  # 每人估價（M2-b 決定）：手填優先；沒填就用「新鮮菜單」推算最便宜餐食 + 最便宜飲料；
  # 只賣飲料的店沒有每人估價（改看 bulk_drink_item 的單價 / 單位）。都算不出來時為 nil（估價未填）。
  PriceEstimate = Data.define(:min, :max, :source) # source: :manual / :menu

  def price_estimate
    if price_per_person_min
      return PriceEstimate.new(min: price_per_person_min, max: price_per_person_max || price_per_person_min, source: :manual)
    end
    return unless offers_food

    fresh = menu_items.select(&:fresh?)
    food = fresh.select(&:category_food?).map(&:price).min
    return unless food

    drink = offers_drink ? fresh.select(&:category_drink?).map(&:price).min : nil
    total = food + drink.to_i
    PriceEstimate.new(min: total, max: total, source: :menu)
  end

  # 只賣飲料的店：最便宜的新鮮飲料項目（顯示「NT$360 / 箱」）
  def bulk_drink_item
    return unless drink_only?

    menu_items.select { |item| item.fresh? && item.category_drink? }.min_by(&:price)
  end

  # 店家最新的菜單日期（卡片顯示用）；沒有菜單或日期都不明時為 nil
  def latest_menu_date = menu_items.map(&:menu_date).compact.max

  # 以最新的菜單日期判斷：沒有菜單 / 日期不明 → :unknown
  def menu_freshness = MenuItem.freshness_of(latest_menu_date)

  # 確認菜單仍有效：該店所有菜單項目的日期改為今天，並記錄驗證時間
  def verify_menu!(on: Date.current)
    transaction do
      menu_items.update_all(menu_date: on, updated_at: Time.current)
      update!(last_verified_at: Time.current)
    end
  end

  # 可能重複的店家：電話（只比數字）或 Instagram 帳號與其他店家相同。只提醒，不擋存檔。
  def possible_duplicates
    others = Merchant.where.not(id: id)
    by_phone = phone.present? ? others.where.not(phone: nil).select { |m| digits(m.phone) == digits(phone) } : []
    by_instagram = instagram.present? ? others.where("LOWER(instagram) = ?", instagram.downcase).to_a : []
    (by_phone + by_instagram).uniq
  end

  # 線上聯絡管道，順序固定：LINE → Instagram → Messenger → 電話（Threads 沒有私訊連結，不列入）。
  # 只回傳有資料的管道；沒有任何管道時回傳空陣列。
  def contact_links
    links = []
    links << [ :line, "https://line.me/R/ti/p/#{line_id}" ] if line_id.present?
    links << [ :instagram, "https://ig.me/m/#{instagram}" ] if instagram.present?
    links << [ :messenger, "https://m.me/#{messenger_id}" ] if messenger_id.present?
    links << [ :phone, "tel:#{phone.gsub(/[^\d+]/, "")}" ] if phone.present?
    links
  end

  private

  def digits(value) = value.to_s.gsub(/\D/, "")

  def normalize_contacts
    self.instagram = instagram.to_s.strip.delete_prefix("@").presence
    self.threads = threads.to_s.strip.delete_prefix("@").presence
    self.line_id = line_id.to_s.strip.presence
    self.messenger_id = messenger_id.to_s.strip.presence
    self.phone = phone.to_s.strip.presence
  end

  def offers_food_or_drink
    errors.add(:base, "至少要販售餐食或飲料其中一種") unless offers_food || offers_drink
  end

  def price_range_in_order
    return if price_per_person_min.nil? || price_per_person_max.nil?

    errors.add(:price_per_person_max, "不可低於最低估價") if price_per_person_max < price_per_person_min
  end
end
