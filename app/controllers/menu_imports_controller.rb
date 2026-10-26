# 貼上菜單：new（輸入）→ preview（預覽，不寫入）→ create（確認後寫入）
class MenuImportsController < ApplicationController
  before_action :set_merchant

  def new
    @menu_import = MenuImport.new(@merchant, import_params)
  end

  def preview
    @menu_import = MenuImport.new(@merchant, import_params)

    if @menu_import.valid?
      render :preview
    else
      render :new, status: :unprocessable_content
    end
  end

  def create
    @menu_import = MenuImport.new(@merchant, import_params)

    if (count = @menu_import.save)
      redirect_to @merchant, notice: "已匯入 #{count} 個菜單項目，菜單日期 #{I18n.l(@menu_import.menu_date, format: :long)}"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_merchant
    @merchant = Merchant.find(params.expect(:merchant_id))
  end

  # GET（從預覽返回修改）時可能沒有參數，所以用 fetch
  def import_params
    params.fetch(:menu_import, {}).permit(:food_text, :drink_text, :menu_date)
  end
end
