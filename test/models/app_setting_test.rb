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

    assert_raises(ActiveRecord::RecordNotUnique) { AppSetting.new.save!(validate: false) }
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

  test "前後空白與多餘空格會整理，空字串存成 nil" do
    setting = AppSetting.instance
    setting.update!(recipient_name: "  王  小明 ", recipient_phone: "   ", delivery_floor: "")

    assert_equal "王 小明", setting.recipient_name
    assert_nil setting.recipient_phone
    assert_nil setting.delivery_floor
  end

  test "收餐地點名稱與地址至少填一個" do
    setting = AppSetting.instance

    assert_not setting.update(delivery_place_name: "", delivery_address: "")
    assert setting.errors.key?(:delivery_place_name)
    assert setting.update(delivery_place_name: "", delivery_address: "台北市某路 1 號")
  end

  test "電話只能有數字與常見符號，其他格式不接受" do
    setting = AppSetting.instance

    assert setting.update(recipient_phone: "+886 (2) 2345-6789 #12")
    assert_not setting.update(recipient_phone: "abc; DROP")
    assert_not setting.update(recipient_phone: "1" * 31)
  end

  test "統一編號：8 碼數字（開頭可以是 0），空白存成 nil" do
    setting = AppSetting.instance

    assert setting.update(tax_id: " 12345678 ")
    assert_equal "12345678", setting.tax_id
    assert setting.update(tax_id: "00123456")
    assert_equal "00123456", setting.reload.tax_id
    assert setting.update(tax_id: "")
    assert_nil setting.tax_id
  end

  test "統一編號：不是 8 碼數字就不接受" do
    setting = AppSetting.instance

    [ "1234567", "123456789", "abcdefgh", "1234-5678", "1234567a" ].each do |value|
      assert_not setting.update(tax_id: value), value
      assert_includes setting.errors.full_messages, "統一編號必須是 8 碼數字", value
    end
  end

  test "統一編號不會寫進詢問訊息的收件資訊" do
    setting = AppSetting.instance
    setting.update!(tax_id: "12345678", recipient_name: "王小明")

    assert_not_includes setting.recipient_text.to_s, "12345678"
  end
end
