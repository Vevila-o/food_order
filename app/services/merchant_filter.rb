# 首頁篩選與排序：把網址參數轉成店家清單，重用 Merchant 既有的 scopes。
#
# 規則（M2-b 決定）：
#   - 19:00 外送：排除「明確不可」，待確認也顯示（否則清單幾乎全空）
#   - 每人 ≤ NT$100：估價算不出來的店仍顯示（卡片標「估價未填」）
#   - 免外送費：外送費明確為 0，或滿額免運且門檻不高於本場預算；外送費未知「不算」免外送
#   - 預設排序：收藏優先，再依最近更新（距離要到 M5 有座標才能排）
# 不認得的參數值一律忽略，不會進到 SQL。
class MerchantFilter
  KINDS = %w[food_and_drink food_only drink_only].freeze
  SORTS = %w[recent name price].freeze
  DEFAULT_SORT = "recent".freeze
  FLAGS = %w[delivers_at_19 free_delivery affordable daan fresh_menu favorited shortlisted never_ordered].freeze
  TRUTHY = %w[1 true on].freeze

  attr_reader :kind, :sort, :flags

  # params：篩選參數（permit 過的 ActionController::Parameters 或 Hash）；budget：本場總預算（免運門檻比較用）
  def initialize(params = {}, budget: nil)
    params = params.to_h.stringify_keys
    @kind = params["kind"].presence_in(KINDS)
    @sort = params["sort"].presence_in(SORTS) || DEFAULT_SORT
    @flags = FLAGS.select { |flag| TRUTHY.include?(params[flag].to_s) }
    @budget = budget
  end

  def flag?(name) = flags.include?(name.to_s)

  # 啟用中的篩選條件數（不含排序），顯示在手機的「篩選 (N)」按鈕
  def active_count = flags.size + (kind ? 1 : 0)

  def active? = active_count.positive?

  def merchants
    result = sorted_relation(filtered_relation).to_a
    result = result.select { |merchant| affordable?(merchant) } if flag?(:affordable)
    result = result.sort_by { |merchant| price_sort_key(merchant) } if sort == "price"
    result
  end

  private

  def filtered_relation
    relation = Merchant.includes(:menu_items, :order_records)
    relation = relation.public_send(kind) if kind
    relation = relation.possibly_delivers_at_19 if flag?(:delivers_at_19)
    relation = relation.free_delivery(@budget) if flag?(:free_delivery)
    relation = relation.in_or_delivers_to_daan if flag?(:daan)
    relation = relation.with_fresh_menu if flag?(:fresh_menu)
    relation = relation.where(favorited: true) if flag?(:favorited)
    relation = relation.where(shortlisted: true) if flag?(:shortlisted)
    relation = relation.never_ordered if flag?(:never_ordered)
    relation
  end

  def sorted_relation(relation)
    case sort
    when "name" then relation.order(:name, :id)
    else relation.order(favorited: :desc, updated_at: :desc, id: :desc) # recent，price 之後在 Ruby 排
    end
  end

  # 估價算不出來（含只賣飲料）→ 仍顯示
  def affordable?(merchant)
    estimate = merchant.price_estimate
    estimate.nil? || estimate.min <= Event::PER_PERSON_BUDGET
  end

  # 估價低 → 高；算不出來的排最後，同價依店名
  def price_sort_key(merchant)
    [ merchant.price_estimate&.min || Float::INFINITY, merchant.name ]
  end
end
