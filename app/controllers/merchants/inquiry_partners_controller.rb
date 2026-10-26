module Merchants
  # 訂單詢問產生器右側面板：可以搭配的另一家店（只負責列清單，挑選由前端帶 partner_id 重新載入產生器）。
  # 候選店家的規則在 InquiryPair.candidates。
  class InquiryPartnersController < ApplicationController
    ROLES = %w[food drink any].freeze

    def index
      @merchant = Merchant.find(params.expect(:merchant_id))
      @event = Event.current
      @role = params.permit(:role)[:role].to_s.presence_in(ROLES) || "any"
      @current_partner_id = params.permit(:partner_id)[:partner_id].to_s
      @candidates = InquiryPair.candidates(merchant: @merchant, role: @role)
      @inquired_ids = @event ? @event.order_inquiries.pluck(:merchant_id) : []
    end

    # 重置：把這間店從配對的組拿掉（給 JavaScript 用）
    def destroy
      merchant = Merchant.find(params.expect(:merchant_id))
      InquiryPair.detach!(event: Event.current, merchant: merchant)
      head :no_content
    end
  end
end
