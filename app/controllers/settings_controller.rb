# 收餐資訊（全站共用、每月不變）：地點一定會寫進詢問訊息；收件人與電話有填才寫。
class SettingsController < ApplicationController
  before_action :set_setting

  def edit
    @event = Event.current
  end

  def update
    if @setting.update(setting_params)
      redirect_to edit_setting_path, notice: "已儲存設定", status: :see_other
    else
      @event = Event.current
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_setting
    @setting = AppSetting.instance
  end

  def setting_params
    params.expect(app_setting: %i[delivery_place_name delivery_address delivery_floor recipient_name recipient_phone tax_id])
  end
end
