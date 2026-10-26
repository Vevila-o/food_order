require "test_helper"

class AppSettingTest < ActiveSupport::TestCase
  test "instance 第一次呼叫會建立並帶入 PicCollage 預設收餐地點" do
    assert_difference "AppSetting.count", 1 do
      AppSetting.instance
    end

    assert_equal "PicCollage 公司總部（台北市大安區光復南路 102 號 3 樓）", AppSetting.instance.delivery_location_text
  end

  test "重複呼叫 instance 永遠是同一列" do
    first = AppSetting.instance

    assert_no_difference "AppSetting.count" do
      assert_equal first, AppSetting.instance
    end
  end

  test "資料庫保證只會有一列" do
    AppSetting.instance

    assert_raises(ActiveRecord::RecordNotUnique) { AppSetting.create! }
  end

  test "收件資訊：有填才顯示，都沒填時為 nil" do
    setting = AppSetting.instance
    assert_nil setting.recipient_text

    setting.update!(recipient_name: "王小明", recipient_phone: "0912-345-678")
    assert_equal "收件人：王小明，電話：0912-345-678", setting.recipient_text

    setting.update!(recipient_phone: nil)
    assert_equal "收件人：王小明", setting.recipient_text
  end

  test "只填地址時地點文字仍通順" do
    setting = AppSetting.instance
    setting.update!(delivery_place_name: nil, delivery_floor: nil)

    assert_equal "（台北市大安區光復南路 102 號）", setting.delivery_location_text
  end
end
