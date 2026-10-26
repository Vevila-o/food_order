module Merchants
  # 訂單詢問產生器（F-06）：選品項與數量 → 金額與預算 → 訊息 → 聯絡按鈕。可同時配對另一家（餐食 + 飲料）。
  # 規則都在 InquiryPair / InquiryForm（表單物件）；金額與訊息只在伺服器算一次，畫面用 Turbo Frame 即時更新，不在 JS 重算。
  class InquiriesController < ApplicationController
    before_action :set_merchant
    before_action :set_pair

    def show
      return redirect_to(edit_setting_path, alert: blocked_message) if @pair.blocked?

      @pair.valid? # 讓畫面顯示數量錯誤、過期品項等訊息
    end

    # 儲存草稿，或（帶 channel 時）把 contact_merchant_id 那一家標為已詢問；給 JavaScript 用，回 JSON
    def create
      channel = params[:channel].presence
      if channel && !OrderInquiry.contacted_via.key?(channel)
        return render json: { errors: [ "不認得的聯絡管道" ] }, status: :unprocessable_content
      end

      inquiries = @pair.save(channel: channel, contact_merchant_id: scalar_param(:contact_merchant_id))
      if inquiries
        render json: inquiries_json(inquiries)
      else
        render json: { errors: @pair.errors.full_messages }, status: :unprocessable_content
      end
    end

    private

    def set_merchant
      @merchant = Merchant.includes(:menu_items, :sources).find(params.expect(:merchant_id))
    end

    def set_pair
      @event = Event.current
      # partner_id：沒帶 = 用已存的組；空字串 = 明確沒有搭檔
      @pair = InquiryPair.new(event: @event, merchant: @merchant, partner_id: scalar_param(:partner_id), quantities: quantities_param)
    end

    # 沒有 quantities 參數 = 第一次打開（套用既有詢問單的品項）；有但不是 Hash（?quantities=oops）當作空的
    def quantities_param
      return unless params.key?(:quantities)

      params.permit(quantities: {})[:quantities].to_h
    end

    # 只收純量（陣列、Hash 一律當沒帶）
    def scalar_param(key) = params.permit(key)[key]

    def blocked_message
      @pair.blocked_reason == :no_event ? "還沒有活動，請先新增活動才能產生詢問訊息" : "還沒有報名人數，請先填寫人數才能計算預算"
    end

    # 最上層的 status / contacted_via 是「被按的那家（沒指定就是主店）」的，給只管單店的呼叫端；inquiries 是全部
    def inquiries_json(inquiries)
      contact_id = (scalar_param(:contact_merchant_id) || @merchant.id).to_i
      contact = inquiries.find { |inquiry| inquiry.merchant_id == contact_id } || inquiries.first
      {
        status: contact.status,
        contacted_via: contact.contacted_via,
        inquiries: inquiries.map { |inquiry| { merchant_id: inquiry.merchant_id, status: inquiry.status, contacted_via: inquiry.contacted_via } }
      }
    end
  end
end
