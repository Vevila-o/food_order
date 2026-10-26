# 首頁篩選表單。variant：
#   :sidebar 桌機左側欄，勾選就自動套用（auto-submit）
#   :drawer  手機底部抽屜，按「套用」才篩選
# 兩者都是 GET 表單，條件放在網址（filter[...]），只更新 merchant-list 這個 Turbo Frame 並更新網址。
class FilterFormComponent < ViewComponent::Base
  FLAG_LABELS = {
    "delivers_at_19" => "可 19:00 外送（含待確認）",
    "free_delivery" => "免外送費",
    "affordable" => "每人 ≤ NT$100",
    "daan" => "大安區內／可送大安區",
    "fresh_menu" => "菜單在 4 個月內",
    "favorited" => "只看收藏",
    "shortlisted" => "只看候選",
    "never_ordered" => "還沒訂過"
  }.freeze

  SORT_LABELS = {
    "recent" => "收藏優先，再依最近更新",
    "name" => "店名",
    "price" => "每人估價低 → 高"
  }.freeze

  def initialize(filter:, variant: :sidebar)
    @filter = filter
    @variant = variant.to_sym
  end

  attr_reader :filter

  def drawer? = @variant == :drawer

  # 同一頁會同時有側欄與抽屜兩份表單，id 加前綴避免重複
  def dom_id_for(name) = "filter-#{@variant}-#{name}"

  def kind_options
    [ [ "全部", "" ] ] + MerchantFilter::KINDS.map { |kind| [ I18n.t("merchant_kind.#{kind}"), kind ] }
  end

  def form_data
    data = { turbo_frame: "merchant-list", turbo_action: "advance" }
    data.merge!(controller: "auto-submit", action: "change->auto-submit#submit") unless drawer?
    data
  end

  def clear_path = helpers.merchants_path
end
