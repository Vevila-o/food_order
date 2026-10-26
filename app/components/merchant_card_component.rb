# 首頁的店家卡片（設計稿）：白底圓角卡片。欄位順序（規格書 8.3）：
#   店名 · 距離 → 食物/飲料標籤 → 每人估價 → 19:00 外送 → 外送費 → 菜單日期 → 收藏、下次候選按鈕
#
# 按鈕由呼叫端用 actions slot 放在右上角（收藏 / 候選切換在階段 5 加入）。
# 「曾訂購」圓點設計稿沒有，放在店名下方的地區 / 距離旁。
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

  # 「大安區 · 0.6 公里」，缺的部分直接省略
  def area_text = [ merchant.district.presence, distance_text ].compact.join(" · ").presence

  def delivers_at_19_text = helpers.enum_text(merchant, :delivers_at_19)

  def delivers_at_19_known? = !merchant.delivers_at_19_unknown?

  def delivery_fee_text = helpers.delivery_fee_text(merchant)

  # 外送費未知要用「待確認」標籤，不是 0
  def delivery_fee_known? = !merchant.delivery_fee.nil?

  def menu_date_text
    date = merchant.latest_menu_date
    date ? "菜單 #{date.strftime('%Y-%m')}" : "尚無菜單日期"
  end

  # 菜單不新鮮（過期 / 日期不明）才多放一個警示標籤，新鮮的不重複說明
  def show_freshness? = merchant.menu_freshness != :fresh
end
