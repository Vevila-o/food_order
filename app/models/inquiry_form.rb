# 訂單詢問產生器的表單物件：選品項與數量 → 小計 + 外送費 → 與總預算比較 → 訊息 → 儲存成詢問單。
#
# 不信任瀏覽器：單價、品名、單位一律由伺服器從 menu_items 帶入，金額與訊息在這裡重算。
# 只接受「屬於這間店、菜單仍有效（≤120 天）」的品項；不認得的品項 id 直接忽略，過期的品項回報錯誤。
# 一場活動對同一間店只有一張詢問單（資料庫唯一索引）：再次儲存會覆蓋品項，已確認訂購的不可覆蓋。
class InquiryForm
  include ActiveModel::Model

  MAX_QUANTITY = 99
  NOTHING_SELECTED = "請至少選一項餐點"
  Line = Data.define(:menu_item, :quantity) do
    def line_total = menu_item.price * quantity
  end

  attr_reader :event, :merchant, :quantities

  # quantities：{ "12" => "3", ... }（menu_item_id => 數量）；沒給就用這場活動既有詢問單的品項當預設
  def initialize(event:, merchant:, quantities: nil)
    @event = event
    @merchant = merchant
    @quantities = normalize(quantities.nil? ? existing_quantities : quantities)
  end

  # 能不能用產生器：要有活動與人數（不會拿 0 人算預算）
  def blocked_reason
    return :no_event if event.nil?

    :no_headcount if event.headcount.nil?
  end

  def blocked? = !blocked_reason.nil?

  # 可以選的品項：菜單有效的，餐食在前、飲料在後
  def orderable_items
    @orderable_items ||= merchant.menu_items.select(&:orderable?).sort_by { |item| [ item.category_food? ? 0 : 1, item.name, item.id ] }
  end

  # 菜單過期或日期不明的品項：不能選，只顯示原因
  def unavailable_items
    @unavailable_items ||= merchant.menu_items.reject(&:orderable?).sort_by { |item| [ item.name, item.id ] }
  end

  def existing_inquiry
    return if event.nil?

    @existing_inquiry ||= event.order_inquiries.includes(:items).find_by(merchant_id: merchant.id)
  end

  # 有選的品項（數量 > 0 且可訂）
  def lines
    @lines ||= orderable_items.filter_map do |item|
      quantity = quantities[item.id]
      # 不是正整數（含 :invalid）的不算有選；錯誤由 quantities_valid 回報
      Line.new(menu_item: item, quantity: quantity) if quantity.is_a?(Integer) && quantity.between?(1, MAX_QUANTITY)
    end
  end

  # 輸入框顯示的數量：沒選或不合法時是 0
  def quantity_for(item) = (quantities[item.id].is_a?(Integer) ? quantities[item.id] : 0)

  def any_lines? = lines.any?

  def confirmed? = existing_inquiry&.confirmed? || false

  # 活動日期已過（不擋，只提醒：下一場日期常常還不確定）
  def event_passed? = !event.nil? && event.held_on < Date.current

  # 要顯示給使用者看的錯誤：還沒選任何品項不算錯誤（剛打開頁面時本來就是空的）。要先呼叫 valid?
  def visible_errors = errors.full_messages - [ NOTHING_SELECTED ]

  def total_quantity = lines.sum(&:quantity)

  def pricing
    @pricing ||= OrderPricing.call(merchant: merchant, lines: lines.map { |line| [ line.menu_item.price, line.quantity ] })
  end

  def message
    @message ||= InquiryMessage.new(
      event: event, location: setting.delivery_location_text, recipient: setting.recipient_text, subtotal: pricing.subtotal,
      lines: lines.map { |line| InquiryMessage::Line.new(name: line.menu_item.name, unit: line.menu_item.unit, quantity: line.quantity) }
    ).text
  end

  # 本場預算：這張（尚未存或會被覆蓋）+ 這場活動其他店家的詢問單
  def budget
    @budget ||= EventBudget.new(event, inquiries: others + [ draft_inquiry ])
  end

  # 本場其他店家已有的詢問單
  def others
    @others ||= event.order_inquiries.where.not(merchant_id: merchant.id).to_a
  end

  # 預算試算用的詢問單（不存資料庫）
  def draft_inquiry
    OrderInquiry.new(event: event, merchant: merchant, headcount_at_creation: event.headcount.to_i,
                     subtotal: pricing.subtotal, delivery_fee: pricing.delivery_fee, total: pricing.total)
  end

  validate :event_and_headcount_present
  validate :quantities_valid
  validate :not_confirmed
  validate :something_selected

  # 存成詢問單（草稿）；channel 有給時（按聯絡按鈕）同時標為已詢問。成功回傳詢問單，失敗回傳 false。
  def save(channel: nil)
    return false unless valid?

    OrderInquiry.transaction do
      inquiry = existing_inquiry || OrderInquiry.new(event: event, merchant: merchant)
      inquiry.assign_attributes(
        headcount_at_creation: event.headcount, subtotal: pricing.subtotal, delivery_fee: pricing.delivery_fee,
        total: pricing.total, message_text: message
      )
      inquiry.save!
      inquiry.items.destroy_all
      lines.each do |line|
        item = line.menu_item
        inquiry.items.create!(menu_item: item, name: item.name, unit: item.unit, quantity: line.quantity, unit_price: item.price)
      end
      inquiry.mark_sent!(channel) if channel
      inquiry
    end
  rescue ActiveRecord::RecordNotUnique
    # 兩個分頁同時儲存：另一邊先建立了，這邊當作衝突
    errors.add(:base, "這場活動已有這間店的詢問單，請重新整理後再試")
    false
  end

  private

  def setting = @setting ||= AppSetting.instance

  def existing_quantities
    return {} unless existing_inquiry

    existing_inquiry.items.each_with_object({}) { |item, hash| hash[item.menu_item_id] = item.quantity if item.menu_item_id }
  end

  # 輸入 → { menu_item_id(Integer) => Integer 或 :invalid }。空白當 0；不是整數記為 :invalid（顯示錯誤，不默默吃掉）
  def normalize(raw)
    raw.to_h.each_with_object({}) do |(id, value), result|
      id = Integer(id.to_s, 10, exception: false)
      next unless id

      result[id] = parse_quantity(value)
    end
  end

  def parse_quantity(value)
    return 0 if value.blank?
    return value if value.is_a?(Integer)

    Integer(value.to_s.strip, 10, exception: false) || :invalid
  end

  def event_and_headcount_present
    case blocked_reason
    when :no_event then errors.add(:base, "還沒有活動，請先到設定新增活動")
    when :no_headcount then errors.add(:base, "還沒有報名人數，請先到設定填寫人數")
    end
  end

  def quantities_valid
    by_id = merchant.menu_items.index_by(&:id)
    quantities.each do |id, quantity|
      item = by_id[id]
      next unless item # 不是這間店的品項：忽略

      if quantity == :invalid || quantity.negative? || quantity > MAX_QUANTITY
        errors.add(:base, "「#{item.name}」的數量必須是 0 到 #{MAX_QUANTITY} 的整數")
      elsif quantity.positive? && !item.orderable?
        errors.add(:base, "「#{item.name}」的菜單日期已過期或不明，請先確認菜單再訂")
      end
    end
  end

  def not_confirmed
    errors.add(:base, "這間店已確認訂購，不能再修改詢問單") if confirmed?
  end

  def something_selected
    errors.add(:base, NOTHING_SELECTED) if errors.empty? && lines.empty?
  end
end
