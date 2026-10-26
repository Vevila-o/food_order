# 側欄「已詢問」：歷史詢問單，最近建立的在前。
class InquiriesController < ApplicationController
  def index
    @inquiries = OrderInquiry.includes(:event, :merchant, order_group: { order_inquiries: :merchant }).latest_first
    @current_event = Event.current
  end
end
