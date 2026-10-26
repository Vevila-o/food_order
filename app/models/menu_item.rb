class MenuItem < ApplicationRecord
  # 「近 4 個月」= 120 天（確認項 #4）；超過的項目不可選，日期不明的也不可選
  FRESH_DAYS = 120

  # 菜單變動時更新店家的 updated_at（列表依「最近更新」排序）
  belongs_to :merchant, touch: true
  belongs_to :source, class_name: "MerchantSource", optional: true

  enum :category, { food: "food", drink: "drink" }, prefix: true, validate: true

  validates :name, presence: true
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :servings, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :menu_date_not_in_future

  # menu_date 是 date 型別，邊界用 Date.current（Asia/Taipei），不用時間戳的 120.days.ago
  scope :fresh, -> { where(menu_date: (Date.current - FRESH_DAYS)..) }
  scope :stale, -> { where(menu_date: ...(Date.current - FRESH_DAYS)) }
  scope :date_unknown, -> { where(menu_date: nil) }

  # 120 天規則只在這裡定義一次：日期 → :fresh / :stale / :unknown
  def self.freshness_of(date)
    if date.nil? then :unknown
    elsif date < Date.current - FRESH_DAYS then :stale
    else :fresh
    end
  end

  def date_unknown? = menu_date.nil?

  def stale? = freshness == :stale

  def fresh? = freshness == :fresh

  # 只有新鮮的菜單項目能進訂單詢問產生器
  alias_method :orderable?, :fresh?

  # :fresh / :stale（菜單可能過期）/ :unknown（日期不明）
  def freshness = self.class.freshness_of(menu_date)

  # 整箱、整桶的約略每人單價；沒填 servings 時為 nil
  def price_per_serving
    price.fdiv(servings).round if servings
  end

  private

  def menu_date_not_in_future
    errors.add(:menu_date, "不可晚於今天") if menu_date && menu_date > Date.current
  end
end
