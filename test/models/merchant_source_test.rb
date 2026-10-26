require "test_helper"

class MerchantSourceTest < ActiveSupport::TestCase
  test "https 網址有效，網址可為空" do
    assert build(:merchant_source, url: "https://www.instagram.com/rubyjam").valid?
    assert build(:merchant_source, url: nil).valid?
  end

  test "只允許 https" do
    assert_not build(:merchant_source, url: "http://example.com/menu").valid?
    assert_not build(:merchant_source, url: "javascript:alert(1)").valid?
    assert_not build(:merchant_source, url: "ftp://example.com/menu").valid?
    assert_not build(:merchant_source, url: "not a url").valid?
  end

  test "擋掉 localhost 與內網 IP（防 SSRF）" do
    %w[
      https://localhost/menu
      https://127.0.0.1/menu
      https://10.0.0.5/menu
      https://192.168.1.10/menu
      https://172.16.0.1/menu
      https://169.254.169.254/latest/meta-data
      https://[::1]/menu
      https://printer.local/menu
      https://db.internal/menu
    ].each do |url|
      assert_not build(:merchant_source, url: url).valid?, "#{url} 應該被擋下"
    end
  end

  test "公開網域與公開 IP 可以" do
    assert build(:merchant_source, url: "https://8.8.8.8/menu").valid?
  end

  test "platform 只接受已知平台" do
    assert_not build(:merchant_source, platform: "tiktok").valid?
  end

  test "刪除來源時，菜單項目保留並清空 source" do
    source = create(:merchant_source)
    item = create(:menu_item, merchant: source.merchant, source: source)

    source.destroy!

    assert_nil item.reload.source_id
  end
end
