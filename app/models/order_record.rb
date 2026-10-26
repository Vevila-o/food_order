# 歷史訂購紀錄。來源：詢問單確認訂購時自動建立（inquiry），或使用者手動補登舊紀錄（manual）。
class OrderRecord < ApplicationRecord
  belongs_to :merchant
  belongs_to :event, optional: true
  belongs_to :order_inquiry, optional: true

  enum :source, { inquiry: "inquiry", manual: "manual" }, prefix: true, validate: true

  validates :headcount, :total, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :ordered_on_not_in_future

  # 日期倒序；日期不明（NULL）排最後。PostgreSQL 的 DESC 預設會把 NULL 排最前面，要明確指定。
  scope :recent_first, -> { order(Arel.sql("ordered_on DESC NULLS LAST, created_at DESC")) }

  private

  def ordered_on_not_in_future
    errors.add(:ordered_on, "不可晚於今天") if ordered_on && ordered_on > Date.current
  end
end
