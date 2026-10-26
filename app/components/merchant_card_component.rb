# 首頁的店家卡片。欄位順序（規格書 8.3）：
#   店名 · 距離 → 食物/飲料標籤 → 每人估價 → 19:00 外送 → 外送費 → 菜單日期 → 收藏、下次候選按鈕
#
# 按鈕由呼叫端用 actions slot 放入（收藏 / 候選切換在 M2-b 階段 5 加入）。
class MerchantCardComponent < ViewComponent::Base
  renders_one :actions

  def initialize(merchant:)
    @merchant = merchant
  end

  attr_reader :merchant

  # 沒有座標（M5 才會自動取得）就不顯示距離
  def distance_text
    km = merchant.distance_km
    "#{km} 公里" if km
  end

  def delivers_at_19_text = helpers.enum_text(merchant, :delivers_at_19)

  def delivery_fee_text = helpers.delivery_fee_text(merchant)

  def menu_date_text = helpers.format_date(merchant.latest_menu_date, fallback: "尚無菜單日期")
end
