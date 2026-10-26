class OrderInquiry < ApplicationRecord
  belongs_to :event
  belongs_to :merchant
  has_many :items, class_name: "OrderInquiryItem", dependent: :destroy, inverse_of: :order_inquiry
  has_one :order_record, dependent: :destroy

  # draft（草稿）→ sent（已按過聯絡按鈕）→ confirmed（已確認訂購）。
  # sent 只代表「按過按鈕」，不代表真的送出，文案要誠實。
  enum :status, { draft: "draft", sent: "sent", confirmed: "confirmed" }, validate: true
  enum :contacted_via, { line: "line", instagram: "instagram", messenger: "messenger", phone: "phone" },
    prefix: :via, validate: { allow_nil: true }

  validates :headcount_at_creation, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :subtotal, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :delivery_fee, :total, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :merchant_id, uniqueness: { scope: :event_id, message: "這場活動已有這間店的詢問單" }

  scope :latest_first, -> { order(created_at: :desc) }

  # 「需調整訂餐」= 最新人數 ≠ 產生詢問單時的人數
  def needs_adjustment?
    current = event.headcount
    !current.nil? && current != headcount_at_creation
  end

  # 點擊任一聯絡按鈕：記錄管道、標為 sent。已確認的詢問單不會被降級。
  def mark_sent!(channel)
    return if confirmed?

    update!(status: :sent, contacted_via: channel, sent_at: Time.current)
  end

  # 確認訂購：在同一個 transaction 內改狀態並建立歷史訂購紀錄
  def confirm!
    return if confirmed?

    transaction do
      update!(status: :confirmed)
      create_order_record!(
        merchant: merchant, event: event, ordered_on: event.held_on,
        headcount: headcount_at_creation, total: total, source: :inquiry
      )
    end
  end

  # 取消確認：退回 sent（或沒按過按鈕就退回 draft），並刪除自動產生的紀錄
  def unconfirm!
    return unless confirmed?

    transaction do
      order_record&.destroy!
      update!(status: sent_at ? :sent : :draft)
    end
  end
end
