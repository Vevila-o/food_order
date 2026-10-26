# 詢問單的品項，是建立當下的「快照」：菜單日後改價或刪除，不影響歷史。
class OrderInquiryItem < ApplicationRecord
  belongs_to :order_inquiry
  belongs_to :menu_item, optional: true

  validates :name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def line_total = unit_price * quantity
end
