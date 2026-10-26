# 側欄「已訂購」：歷史訂購紀錄（OrderRecord），日期倒序，日期不明的排最後。
class OrdersController < ApplicationController
  def index
    @order_records = OrderRecord.includes(:merchant).recent_first
  end
end
