# 側欄「已詢問」：歷史詢問單，最近建立的在前。
class InquiriesController < ApplicationController
  def index
    @inquiries = OrderInquiry.includes(:event, :merchant).latest_first
  end
end
