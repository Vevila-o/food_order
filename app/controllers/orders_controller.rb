# 側欄「已訂購」：歷史訂購紀錄（OrderRecord），日期倒序，日期不明的排最後。
# 可以補登（手動新增）過去訂過的店家；只能刪除手動補登的，詢問單產生的要到「已詢問」按叉叉取消。
class OrdersController < ApplicationController
  def index
    @order_records = OrderRecord.includes(:merchant).recent_first
  end

  def new
    @order_record = OrderRecord.new(ordered_on: Date.current, merchant_id: merchant_id_param)
    load_merchants
  end

  def create
    @order_record = OrderRecord.new(order_record_params.merge(source: :manual))

    if @order_record.save(context: :manual_entry)
      redirect_to orders_path, notice: "已補登「#{@order_record.merchant.name}」的訂購紀錄", status: :see_other
    else
      load_merchants
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    record = OrderRecord.find(params.expect(:id))
    if record.source_manual?
      record.destroy!
      redirect_to orders_path, notice: "已刪除「#{record.merchant.name}」的補登紀錄", status: :see_other
    else
      redirect_to orders_path, alert: "這筆是從詢問單確認訂購產生的，請到「已詢問」按叉叉取消訂購", status: :see_other
    end
  end

  private

  def load_merchants
    @merchants = Merchant.order(:name)
  end

  # 從店家頁的「補登訂購」連結帶入店家
  def merchant_id_param = params.permit(:merchant_id)[:merchant_id]

  def order_record_params
    params.expect(order_record: %i[merchant_id ordered_on headcount total note])
  end
end
