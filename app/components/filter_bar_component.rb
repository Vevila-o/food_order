# 首頁篩選列（設計稿）：橫向可捲動的膠囊按鈕 + 「更多篩選」按鈕，更多條件放底部抽屜（dialog）。
#
# 單一 GET 表單（id=filter-form），抽屜裡的欄位用 form="filter-form" 屬性歸屬同一個表單，
# 所以膠囊與抽屜的狀態永遠一致。膠囊勾選就自動送出；抽屜按「套用」才送出。
# 只更新 merchant-list 這個 Turbo Frame 並更新網址（條件可分享）。
# 膠囊是原生 checkbox（鍵盤與讀屏都可用），用 peer-checked 變色。
class FilterBarComponent < ViewComponent::Base
  FORM_ID = "filter-form".freeze

  # 膠囊列：[參數名, 值, 文字]。類型是 filter[kinds][]（可複選），其餘是 filter[<旗標>]=1
  CHIPS = [
    [ "kinds", "food_and_drink", "餐＋飲" ],
    [ "delivers_at_19", "1", "19:00 可外送" ],
    [ "free_delivery", "1", "免外送費" ],
    [ "affordable", "1", "每人 ≤ NT$100" ],
    [ "fresh_menu", "1", "菜單 4 個月內" ],
    [ "favorited", "1", "只看收藏" ],
    [ "shortlisted", "1", "只看候選" ]
  ].freeze

  # 抽屜裡的其他條件（設計稿沒有的）
  DRAWER_CHECKS = [
    [ "kinds", "food_only", "只有餐" ],
    [ "kinds", "drink_only", "僅飲料" ],
    [ "daan", "1", "大安區內／可送大安區" ],
    [ "never_ordered", "1", "還沒訂過" ]
  ].freeze

  SORT_LABELS = {
    "recent" => "收藏優先，再依最近更新",
    "name" => "店名",
    "price" => "每人估價低 → 高"
  }.freeze

  def initialize(filter:)
    @filter = filter
  end

  attr_reader :filter

  def form_id = FORM_ID

  def clear_path = helpers.merchants_path

  def checked?(name, value)
    name == "kinds" ? filter.kind?(value) : filter.flag?(name)
  end

  def input_name(name) = name == "kinds" ? "filter[kinds][]" : "filter[#{name}]"

  def input_id(name, value) = "filter-#{name}-#{value}"

  # 抽屜裡已啟用的條件數，顯示在「更多篩選」按鈕上讓人知道有隱藏的條件
  def drawer_active_count
    DRAWER_CHECKS.count { |name, value, _| checked?(name, value) } + (filter.sort == MerchantFilter::DEFAULT_SORT ? 0 : 1)
  end
end
