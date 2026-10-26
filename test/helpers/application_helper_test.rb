require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "enum_text 把列舉值轉成中文" do
    assert_equal "待確認", enum_text(build(:merchant), :delivers_at_19)
    assert_equal "可以", enum_text(build(:merchant, delivers_at_19: "yes"), :delivers_at_19)
    assert_equal "不行", enum_text(build(:merchant, delivers_at_19: "no"), :delivers_at_19)
    assert_equal "飲料", enum_text(build(:menu_item, :drink), :category)
    assert_equal "已確認訂購", enum_text(build(:order_inquiry, status: "confirmed"), :status)
  end

  test "enum_text 沒有值時回傳 nil" do
    assert_nil enum_text(build(:order_inquiry), :contacted_via)
  end

  test "所有列舉值都有中文翻譯（避免畫面出現 translation missing）" do
    {
      Merchant => %i[delivers_at_19 delivers_to_daan],
      MenuItem => %i[category],
      MerchantSource => %i[platform],
      OrderInquiry => %i[status contacted_via],
      OrderRecord => %i[source]
    }.each do |model, attributes|
      attributes.each do |attribute|
        model.public_send(attribute.to_s.pluralize).each_key do |value|
          key = "enums.#{model.model_name.i18n_key}.#{attribute}.#{value}"
          assert I18n.exists?(key), "缺少翻譯：#{key}"
        end
      end
    end
  end

  test "金額：整數加千分位，未知顯示待確認而不是 NT$0" do
    assert_equal "NT$1,620", format_money(1620)
    assert_equal "NT$0", format_money(0)
    assert_equal "待確認", format_money(nil)
    assert_equal "—", format_money(nil, unknown: "—")
  end

  test "日期顯示與缺值" do
    assert_equal "未填", format_date(nil)
    assert_includes format_date(Date.new(2026, 10, 27)), "2026"
  end

  test "flash 樣式" do
    assert_equal "alert-success", flash_class(:notice)
    assert_equal "alert-warning", flash_class("alert")
    assert_equal "alert-info", flash_class(:other)
  end
end
