# 單列設定表：收餐資訊全站共用、每月不變。資料庫以固定欄位 + 唯一索引保證只有一列。
class AppSetting < ApplicationRecord
  DEFAULTS = {
    delivery_place_name: "PicCollage 公司總部",
    delivery_address: "台北市大安區光復南路 102 號",
    delivery_floor: "3 樓"
  }.freeze

  PHONE_FORMAT = /\A[0-9+\-()\s#]+\z/

  normalizes :delivery_place_name, :delivery_address, :delivery_floor, :recipient_name, :recipient_phone,
             with: ->(value) { value.to_s.squish.presence }

  validates :delivery_place_name, :delivery_address, :delivery_floor, :recipient_name, length: { maximum: 100 }
  validates :recipient_phone, length: { maximum: 30 }, format: { with: PHONE_FORMAT, message: "只能填數字、+、-、括號與空格" }, allow_nil: true
  validate :delivery_location_present

  def self.instance
    find_by(singleton: true) || create_or_find_by!(singleton: true) { |setting| setting.assign_attributes(DEFAULTS) }
  end

  # 詢問訊息中的 {地點}，例如「PicCollage 公司總部（台北市大安區光復南路 102 號 3 樓）」
  def delivery_location_text
    address = [ delivery_address, delivery_floor ].compact_blank.join(" ")
    [ delivery_place_name, address.presence && "（#{address}）" ].compact_blank.join
  end

  # 收件資訊，例如「收件人：王小明，電話：0912-345-678」；都沒填時為 nil
  def recipient_text
    parts = []
    parts << "收件人：#{recipient_name}" if recipient_name.present?
    parts << "電話：#{recipient_phone}" if recipient_phone.present?
    parts.join("，").presence
  end

  private

  # 詢問訊息一定要寫收餐地點：名稱與地址至少填一個
  def delivery_location_present
    return if delivery_place_name.present? || delivery_address.present?

    errors.add(:delivery_place_name, "與收餐地址至少要填一個")
  end
end
