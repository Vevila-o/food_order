module Merchants
  # 訂單詢問產生器（F-06）：選品項與數量 → 金額與預算 → 訊息 → 聯絡按鈕。
  # 金額與訊息只在伺服器（InquiryForm / InquiryMessage）算一次；畫面用 Turbo Frame 即時更新，不在 JS 重算。
  class InquiriesController < ApplicationController
    before_action :set_merchant
    before_action :set_form

    def show
      return redirect_to(edit_setting_path, alert: blocked_message) if @form.blocked?

      @form.valid? # 讓畫面顯示數量錯誤、過期品項等訊息
    end

    # 儲存草稿，或（帶 channel 時）標為已詢問；給 JavaScript 用，回 JSON
    def create
      channel = params[:channel].presence
      if channel && !OrderInquiry.contacted_via.key?(channel)
        return render json: { errors: [ "不認得的聯絡管道" ] }, status: :unprocessable_content
      end

      inquiry = @form.save(channel: channel)
      if inquiry
        render json: { status: inquiry.status, contacted_via: inquiry.contacted_via }
      else
        render json: { errors: @form.errors.full_messages }, status: :unprocessable_content
      end
    end

    private

    def set_merchant
      @merchant = Merchant.includes(:menu_items, :sources).find(params.expect(:merchant_id))
    end

    def set_form
      @event = Event.current
      @form = InquiryForm.new(event: @event, merchant: @merchant, quantities: quantities_param)
    end

    # 沒有 quantities 參數 = 第一次打開（套用既有詢問單的品項）；有但不是 Hash（?quantities=oops）當作空的
    def quantities_param
      return unless params.key?(:quantities)

      params.permit(quantities: {})[:quantities].to_h
    end

    def blocked_message
      @form.blocked_reason == :no_event ? "還沒有活動，請先新增活動才能產生詢問訊息" : "還沒有報名人數，請先填寫人數才能計算預算"
    end
  end
end
