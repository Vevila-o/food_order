module Inquiries
  # 「已詢問」頁的訂購按鈕：記錄這家有訂購（OrderInquiry#confirm!）。
  # 會同時建立一筆訂購紀錄（source: inquiry），所以店家卡片的「曾訂購」圓點與側欄的「已訂購」數量都會更新；
  # 取消（unconfirm!）會刪掉自動產生的那筆。兩個動作都可重複按（冪等）。配對的兩家各自記錄。
  class ConfirmationsController < ApplicationController
    before_action :set_inquiry

    def create
      @inquiry.confirm!
      redirect_to inquiries_path, notice: "已記錄「#{@inquiry.merchant.name}」為已訂購", status: :see_other
    end

    def destroy
      @inquiry.unconfirm!
      redirect_to inquiries_path, notice: "已取消「#{@inquiry.merchant.name}」的訂購紀錄", status: :see_other
    end

    private

    def set_inquiry
      @inquiry = OrderInquiry.includes(:merchant).find(params.expect(:inquiry_id))
    end
  end
end
