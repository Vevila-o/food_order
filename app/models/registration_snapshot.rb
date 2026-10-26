# 報名人數快照：只存人數與時間，不存報名者姓名、email。
class RegistrationSnapshot < ApplicationRecord
  belongs_to :event

  enum :source, { webhook: "webhook", manual: "manual" }, prefix: true, validate: true

  before_validation { self.received_at ||= Time.current }

  validates :headcount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # 同一筆 KKTIX 訂單 + 事件類型只算一次（資料庫也有部分唯一索引）
  validates :kktix_order_id, uniqueness: { scope: [ :event_id, :kktix_event_type ] }, allow_nil: true
end
