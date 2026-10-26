# 兩家配對訂購（一家餐食 + 一家飲料）的表單物件。
#
# 包兩個既有的 InquiryForm（單店的驗證、金額、訊息規則完全沿用），負責配對才有的規則：
#   - 搭檔從哪來：網址 partner_id（空字串 = 明確沒有）> 這間店詢問單所在組的另一家（兩張都還是草稿才自動帶出；
#     已經按過聯絡按鈕（已詢問）的，重新打開就是乾淨的單店，要從「已詢問」頁進來才會帶 partner_id）
#   - 兩家合計（小計、外送費、預計金額；有外送費未知就是 nil）與總預算比較：只算目前這一家或配對的兩家，不含本場其他店家
#   - 儲存：兩家一起存、綁成一組（OrderGroup）、只有被按聯絡按鈕的那家標為已詢問
#   - 換搭檔 / 移除：舊搭檔的詢問單保留，只是離組；組內不足兩張就刪組
#
# 數量用扁平的 { menu_item_id => 數量 }，兩家共用（品項 id 全域唯一，各 form 只認自己店的品項）。
# 某一家的品項完全沒出現在請求裡（例如剛選了搭檔），就用它已存的詢問單當預設。
class InquiryPair
  include ActiveModel::Model

  # 主店種類 → 要找哪一種搭檔：飲料店找餐食、餐食店找飲料、餐＋飲則都可以
  PARTNER_ROLES = { drink_only: :food, food_only: :drink, food_and_drink: :any }.freeze
  Combined = Data.define(:subtotal, :delivery_fee, :total)

  attr_reader :event, :merchant, :main, :partner

  # partner_id：nil = 沒有指定（用既有組的搭檔）、"" = 明確沒有搭檔、其他 = 店家 id（不存在或是主店自己就當沒有）
  def initialize(event:, merchant:, partner_id: nil, quantities: nil)
    @event = event
    @merchant = merchant
    partner_merchant = resolve_partner(partner_id)
    @main = InquiryForm.new(event: event, merchant: merchant, quantities: quantities_for(merchant, quantities))
    @partner = partner_merchant && InquiryForm.new(event: event, merchant: partner_merchant, quantities: quantities_for(partner_merchant, quantities))
  end

  # 右側清單要找哪一種搭檔：:food / :drink / :any
  def partner_role = PARTNER_ROLES.fetch(merchant.kind)

  # 右側清單的候選店家：含餐＋飲的店（選飲料 = 賣飲料的店，選餐食 = 賣餐食的店），排除主店與「明確不外送 19:00」的店；
  # 排序：下次訂購 → 收藏 → 最近更新
  def self.candidates(merchant:, role:)
    scope = Merchant.where.not(id: merchant.id).possibly_delivers_at_19.includes(:menu_items, :order_records)
    scope = scope.where(offers_drink: true) if role.to_s == "drink"
    scope = scope.where(offers_food: true) if role.to_s == "food"
    scope.order(shortlisted: :desc, favorited: :desc, updated_at: :desc, id: :desc)
  end

  # 重置：這間店的詢問單離組（兩張詢問單與它們的狀態都保留），之後只算這一家。沒有組就什麼都不做。
  def self.detach!(event:, merchant:)
    inquiry = event&.order_inquiries&.find_by(merchant_id: merchant.id)
    group = inquiry&.order_group
    return unless group

    OrderInquiry.transaction do
      inquiry.update!(order_group: nil)
      group.reload
      group.destroy! if group.order_inquiries.size < 2
    end
  end

  def forms = [ main, partner ].compact

  def two_merchants? = !partner.nil?

  # 有選品項的那幾家（沒選的不計金額，也不會多算一筆外送費）
  def selected_forms = forms.select(&:any_lines?)

  def any_lines? = selected_forms.any?

  def blocked_reason = main.blocked_reason

  def blocked? = main.blocked?

  def event_passed? = main.event_passed?

  # 兩家合計；任何一家外送費未知，外送費與總額就是 nil（待確認）
  def combined
    @combined ||= begin
      prices = selected_forms.map(&:pricing)
      fees = prices.map(&:delivery_fee)
      fee = fees.include?(nil) ? nil : fees.sum
      subtotal = prices.sum(&:subtotal)
      Combined.new(subtotal: subtotal, delivery_fee: fee, total: fee && subtotal + fee)
    end
  end

  # 預算比較：只算目前這一家或配對的兩家（有選品項的試算），不含本場其他店家的詢問單
  def budget
    @budget ||= EventBudget.new(event, inquiries: selected_forms.map(&:draft_inquiry))
  end

  validate :forms_valid
  validate :something_selected

  # 要顯示給使用者看的錯誤（先呼叫 valid?）：「還沒選任何品項」不算錯誤（剛打開頁面本來就是空的）
  def visible_errors = errors.full_messages - [ InquiryForm::NOTHING_SELECTED ]

  # 兩家（有選品項的）一起存並綁成一組。channel 只標在 contact_merchant_id 那一家（沒指定就是主店）。
  # 成功回傳存好的詢問單陣列，失敗回傳 false（錯誤在 errors）。
  def save(channel: nil, contact_merchant_id: nil)
    return false unless valid?

    contact_id = (contact_merchant_id || merchant.id).to_i
    if channel && selected_forms.none? { |form| form.merchant.id == contact_id }
      errors.add(:base, "這間店還沒選餐點，不能標為已詢問")
      return false
    end

    inquiries = nil
    OrderInquiry.transaction do
      inquiries = selected_forms.map { |form| form.save(channel: (channel if form.merchant.id == contact_id)) }
      if inquiries.include?(false)
        selected_forms.each { |form| form.errors.full_messages.each { |message| errors.add(:base, message) } }
        raise ActiveRecord::Rollback
      end
      regroup(inquiries) if inquiries.size == 2
    end
    inquiries.include?(false) ? false : inquiries
  end

  private

  # nil → 用既有組的搭檔；"" → 沒有；id → 該店（不存在或是主店自己就沒有）
  def resolve_partner(partner_id)
    return existing_partner if partner_id.nil?
    return if partner_id.to_s.empty?

    found = Merchant.includes(:menu_items, :order_records).find_by(id: partner_id)
    found unless found.nil? || found.id == merchant.id
  end

  # 已詢問（sent / confirmed）就不自動帶出：那一組已經送出去了，重新打開是新的開始
  def existing_partner
    return if event.nil?

    inquiry = event.order_inquiries.find_by(merchant_id: merchant.id)
    other = inquiry&.partner
    other&.merchant if other && inquiry.draft? && other.draft?
  end

  # 該店的品項有出現在請求裡才用請求的數量，否則回傳 nil 讓 InquiryForm 用既有詢問單當預設
  def quantities_for(shop, quantities)
    return if quantities.nil?

    ids = shop.menu_items.map(&:id)
    given = quantities.to_h.select { |id, _| ids.include?(Integer(id.to_s, 10, exception: false)) }
    given.empty? ? nil : given
  end

  def forms_valid
    forms.each do |form|
      form.valid?
      form.errors.full_messages.each do |message|
        next if message == InquiryForm::NOTHING_SELECTED

        errors.add(:base, two_merchants? ? "#{form.merchant.name}：#{message}" : message)
      end
    end
  end

  def something_selected
    errors.add(:base, InquiryForm::NOTHING_SELECTED) if errors.empty? && selected_forms.empty?
  end

  # 兩張詢問單綁成一組：沿用「成員都在這兩張裡」的舊組，否則新建；其他舊組只剩一張就刪掉（那張保留，離組）
  def regroup(inquiries)
    old_groups = inquiries.filter_map(&:order_group).uniq
    ids = inquiries.map(&:id)
    target = old_groups.find { |group| (group.order_inquiry_ids - ids).empty? } || OrderGroup.create!(event: event)
    inquiries.each { |inquiry| inquiry.update!(order_group: target) unless inquiry.order_group_id == target.id }
    (old_groups - [ target ]).each do |group|
      group.reload
      group.destroy! if group.order_inquiries.size < 2
    end
  end
end
