module Merchants
  # 收藏 / 下次候選切換的共同邏輯。Turbo 請求只替換被按的那顆按鈕（不重整頁面），沒有 JavaScript 時退回 redirect。
  class TogglesController < ApplicationController
    before_action :set_merchant

    private

    def set_merchant
      @merchant = Merchant.find(params.expect(:merchant_id))
    end

    def respond_with_button(kind)
      respond_to do |format|
        format.turbo_stream do
          button = view_context.render(ToggleButtonComponent.new(merchant: @merchant, kind: kind))
          render turbo_stream: turbo_stream.replace(ToggleButtonComponent.dom_id_for(@merchant, kind), button)
        end
        format.html { redirect_back_or_to merchant_path(@merchant), status: :see_other }
      end
    end
  end
end
