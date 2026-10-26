require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "設定頁：收餐資訊表單帶入預設的 PicCollage 地點" do
    get edit_setting_path

    assert_response :success
    assert_select "input[name='app_setting[delivery_place_name]'][value='PicCollage 公司總部']"
    assert_select "input[name='app_setting[delivery_address]'][value='台北市大安區光復南路 102 號']"
    assert_select "input[name='app_setting[delivery_floor]'][value='3 樓']"
    assert_select "input[name='app_setting[recipient_phone]']"
    assert_select "strong", text: "會傳給每一間詢問的店家"
  end

  test "沒有活動：提示新增；有活動：顯示摘要與編輯連結" do
    get edit_setting_path
    assert_select "a[href='#{new_event_path}']", text: "新增活動"

    event = create(:event, :with_headcount, headcount: 18)
    get edit_setting_path

    assert_select "a[href='#{edit_event_path(event)}']"
    assert_select "a[href='#{new_event_path}']", text: "新增下一場"
    assert_select "section", text: /18 人/
  end

  test "設定頁有統一編號欄位（選填，說明只存在這裡）" do
    get edit_setting_path

    assert_select "legend", text: "發票（選填）"
    assert_select "input[name='app_setting[tax_id]'][maxlength='8'][inputmode=numeric]"
    assert_select "p", text: /不會寫進詢問訊息/
  end

  test "儲存統一編號；頁面帶出已存的值" do
    patch setting_path, params: { app_setting: { delivery_place_name: "辦公室", tax_id: "12345678" } }

    assert_redirected_to edit_setting_path
    assert_equal "12345678", AppSetting.instance.tax_id
    follow_redirect!
    assert_select "input[name='app_setting[tax_id]'][value='12345678']"
  end

  test "統一編號格式錯誤：顯示錯誤、不儲存" do
    patch setting_path, params: { app_setting: { delivery_place_name: "辦公室", tax_id: "123" } }

    assert_response :unprocessable_content
    assert_select ".alert", text: /統一編號必須是 8 碼數字/
    assert_nil AppSetting.instance.tax_id
  end

  test "儲存收餐資訊" do
    patch setting_path, params: { app_setting: { delivery_place_name: "新辦公室", delivery_address: "台北市某路 1 號", delivery_floor: "5 樓", recipient_name: "王小明", recipient_phone: "0912-345-678" } }

    assert_redirected_to edit_setting_path
    setting = AppSetting.instance
    assert_equal "新辦公室（台北市某路 1 號 5 樓）", setting.delivery_location_text
    assert_equal "收件人：王小明，電話：0912-345-678", setting.recipient_text
  end

  test "名稱與地址都清空：顯示錯誤、不儲存" do
    patch setting_path, params: { app_setting: { delivery_place_name: "", delivery_address: "" } }

    assert_response :unprocessable_content
    assert_select ".alert", text: /至少要填一個/
    assert_equal "PicCollage 公司總部", AppSetting.instance.delivery_place_name
  end

  test "不能藉由參數改到其他欄位" do
    patch setting_path, params: { app_setting: { delivery_place_name: "X", singleton: false, id: 99 } }

    assert_redirected_to edit_setting_path
    assert AppSetting.instance.singleton
  end

  test "首頁有設定齒輪連結；沒有活動時提示新增" do
    get root_path

    assert_select "header a[aria-label=設定][href='#{edit_setting_path}']"
    assert_select ".alert", text: /還沒有活動/
    assert_select "a[href='#{new_event_path}']"
  end

  test "首頁活動摘要有修正人數連結" do
    event = create(:event, :with_headcount, held_on: Date.current.next_occurring(:tuesday))

    get root_path

    assert_select "a[href='#{edit_event_path(event)}']", text: "修正人數"
    assert_select ".alert", text: /還沒有活動/, count: 0
  end
end
