# 右側面板的店家卡（像選機票的清單）：重點是「選這家」，所以不放收藏 / 候選按鈕，也不開店家頁。
# 菜單全部過期或日期不明的店照列，但按鈕停用（產生器只接受 120 天內的品項）。
class PartnerPickCardComponent < ViewComponent::Base
  # selected：目前已選的搭檔；inquired：這場活動已有這間店的詢問單
  def initialize(merchant:, selected: false, inquired: false)
    @merchant = merchant
    @selected = selected
    @inquired = inquired
  end

  attr_reader :merchant

  def selected? = @selected

  def inquired? = @inquired

  # 有任何一個 120 天內的菜單項目才能選
  def orderable? = merchant.menu_items.any?(&:orderable?)

  def disabled? = selected? || !orderable?

  def button_label
    if selected? then "目前選擇"
    elsif !orderable? then "菜單可能過期"
    else "選這家"
    end
  end

  def delivers_at_19_known? = !merchant.delivers_at_19_unknown?

  def delivery_fee_known? = !merchant.delivery_fee.nil?

  def area_text = [ merchant.district.presence, ("#{merchant.distance_km} 公里" if merchant.distance_km) ].compact.join(" · ").presence

  def menu_date_text
    date = merchant.latest_menu_date
    date ? "菜單 #{date.strftime('%Y-%m')}" : "尚無菜單日期"
  end

  def show_freshness? = merchant.menu_freshness != :fresh
end
