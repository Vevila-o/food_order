# 「貼上菜單」的表單物件（不對應資料表）：餐食 / 飲料各一段文字，整批共用一個菜單日期。
#
# 流程：貼上 → 預覽（rows）→ 確認才寫入（save）。確認時會重新解析，不信任瀏覽器傳來的內容。
# 同一家店、同類別、同品名已存在時，更新價格與日期（每月更新菜單），不會產生重複項目。
class MenuImport
  include ActiveModel::Model
  include ActiveModel::Attributes

  MAX_TEXT_LENGTH = 5_000
  MAX_ITEMS = 100
  CATEGORIES = { food_text: "food", drink_text: "drink" }.freeze

  # action：:new 新增 / :update 更新既有項目；old_price 只有更新時有值
  Row = Data.define(:category, :name, :price, :action, :old_price)

  attr_reader :merchant

  attribute :food_text, :string
  attribute :drink_text, :string
  attribute :menu_date, :date

  validates :menu_date, presence: true
  validates :food_text, :drink_text, length: { maximum: MAX_TEXT_LENGTH }
  validate :menu_date_not_in_future
  validate :something_to_import
  validate :texts_parse
  validate :not_too_many_items

  def initialize(merchant, attributes = {})
    @merchant = merchant
    super(attributes)
  end

  # 預覽用：解析後的每一列，並標示新增或更新
  def rows
    @rows ||= parsed.flat_map do |attribute, result|
      category = CATEGORIES.fetch(attribute)
      result.items.map do |item|
        existing = existing_items[[ category, item.name ]]
        Row.new(category: category, name: item.name, price: item.price,
                action: existing ? :update : :new, old_price: existing&.price)
      end
    end
  end

  # 寫入資料庫；驗證不過回傳 false。成功回傳寫入的筆數。
  def save
    return false unless valid?

    MenuItem.transaction do
      rows.each do |row|
        item = existing_items[[ row.category, row.name ]] || merchant.menu_items.build(category: row.category, name: row.name)
        item.update!(price: row.price, menu_date: menu_date)
      end
    end
    rows.size
  end

  private

  # { food_text: Result, drink_text: Result }
  def parsed
    @parsed ||= CATEGORIES.keys.index_with { |attribute| MenuTextParser.call(public_send(attribute)) }
  end

  def existing_items
    @existing_items ||= merchant.menu_items.index_by { |item| [ item.category, item.name ] }
  end

  def menu_date_not_in_future
    errors.add(:menu_date, "不可晚於今天") if menu_date && menu_date > Date.current
  end

  def something_to_import
    return if food_text.present? || drink_text.present?

    errors.add(:base, "請至少貼上一段菜單（餐食或飲料）")
  end

  def texts_parse
    parsed.each do |attribute, result|
      result.errors.each do |line_error|
        prefix = line_error.line.zero? ? "" : "第 #{line_error.line} 行「#{line_error.text}」："
        errors.add(attribute, "#{prefix}#{line_error.message}")
      end
    end
  end

  def not_too_many_items
    return if errors.any? # 解析有錯時先修正錯誤

    errors.add(:base, "一次最多匯入 #{MAX_ITEMS} 個品項") if rows.size > MAX_ITEMS
  end
end
