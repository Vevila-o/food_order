require "test_helper"

class PartnerPickCardComponentTest < ViewComponent::TestCase
  def card(merchant, **options)
    render_inline(PartnerPickCardComponent.new(merchant: merchant, **options))
  end

  def fresh_merchant(**attrs)
    create(:merchant, **attrs).tap { |merchant| create(:menu_item, merchant: merchant) }.reload
  end

  test "顯示店名、類型、外送費，按鈕帶店家 id 給 inquiry controller" do
    merchant = fresh_merchant(name: "涼飲店", delivery_fee: 50)

    card(merchant)

    assert_selector "h3", text: "涼飲店"
    assert_text "NT$50"
    assert_selector "button[data-action='inquiry#pickPartner'][data-inquiry-partner-id-param='#{merchant.id}']:not([disabled])", text: "選這家"
  end

  test "菜單全部過期：照列但按鈕停用並說明" do
    merchant = create(:merchant, name: "舊菜店")
    create(:menu_item, :stale, merchant: merchant)

    card(merchant.reload)

    assert_selector "button[disabled]", text: "菜單可能過期"
    assert_selector "span", text: "菜單可能過期", minimum: 1
  end

  test "沒有任何菜單：不能選" do
    card(create(:merchant))

    assert_selector "button[disabled]"
  end

  test "已選：按鈕停用、顯示目前選擇、外框強調" do
    card(fresh_merchant, selected: true)

    assert_selector "article.ring-primary"
    assert_selector "button[disabled]", text: "目前選擇"
  end

  test "這場已有詢問單：標示" do
    card(fresh_merchant, inquired: true)

    assert_selector "span", text: "已有詢問單"
  end

  test "外送費未知：用待確認標籤，不是 NT$0" do
    card(fresh_merchant)

    assert_selector "span.bg-secondary", text: "待確認", minimum: 1
    assert_no_text "NT$0"
  end

  test "沒有收藏與候選按鈕（這是挑選用的卡片）" do
    card(fresh_merchant)

    assert_no_selector "button[aria-label=收藏]"
    assert_no_selector "a"
  end

  test "45 天內訂過：提示上次剛訂過" do
    travel_to Time.zone.local(2026, 10, 27, 12, 0) do
      merchant = fresh_merchant
      create(:order_record, merchant: merchant, ordered_on: Date.new(2026, 10, 20))

      card(merchant.reload)

      assert_selector "span.bg-secondary", text: "上次剛訂過 10/20"
    end
  end
end
