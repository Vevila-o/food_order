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

  # GET（從預覽返回修改）時可能沒有參數；menu_import 不是 Hash 時 permit 會丟掉它，不會 500
  def import_params
    params.permit(menu_import: %i[food_text drink_text menu_date])[:menu_import].to_h
  end
end
