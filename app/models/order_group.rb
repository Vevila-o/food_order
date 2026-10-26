# 同一場活動、同時詢問的店家（一家餐食 + 一家飲料）。目前最多兩張詢問單。
# 詢問單離組只是把 order_group_id 清掉（詢問單與它的狀態、紀錄都保留）；組內不足兩張就沒有意義，由 InquiryPair 清掉。
class OrderGroup < ApplicationRecord
  MAX_INQUIRIES = 2

  belongs_to :event
  has_many :order_inquiries, dependent: :nullify

  validate :inquiries_within_limit

  private

  def inquiries_within_limit
    return if order_inquiries.size <= MAX_INQUIRIES

    errors.add(:base, "一組最多 #{MAX_INQUIRIES} 家")
  end
end
