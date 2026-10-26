require "test_helper"

class MerchantCardComponentTest < ViewComponent::TestCase
  def render_card(merchant, &)
    render_inline(MerchantCardComponent.new(merchant: merchant), &)
  end

  test "顯示店名並連到店家頁" do
    merchant = create(:merchant, name: "阿嬤便當")

    render_card(merchant)

    assert_selector "h2 a[href='/merchants/#{merchant.id}']", text: "阿嬤便當"
  end

  test "沒有座標時不顯示距離" do
    render_card(create(:merchant))

    assert_no_text "公里"
  end

  test "有座標時顯示到 PicCollage 的距離" do
    render_card(create(:merchant, lat: Merchant::PICCOLLAGE_LAT + 0.01, lng: Merchant::PICCOLLAGE_LNG))

    assert_text "1.11 公里"
  end

  test "標籤與每人估價" do
    merchant = create(:merchant, :food_and_drink, price_per_person_min: 80, price_per_person_max: 100)

    render_card(merchant)

    assert_selector "span.bg-accent", text: "餐＋飲"
    assert_text "每人 NT$80–100"
  end

  test "19:00 外送：預設待確認，可以 / 不行" do
    render_card(create(:merchant))
    assert_text "待確認"

    render_card(create(:merchant, delivers_at_19: "yes"))
    assert_text "可以"

    render_card(create(:merchant, delivers_at_19: "no"))
    assert_text "不行"
  end

  test "外送費未知顯示待確認，不是 0" do
    render_card(create(:merchant, delivery_fee: nil))

    assert_selector "dd span.bg-secondary", text: "待確認", count: 2 # 19:00 外送與外送費都待確認
    assert_no_text "NT$0"
  end

  test "外送費 0 顯示免外送費，有外送費顯示金額" do
    render_card(create(:merchant, delivery_fee: 0))
    assert_text "免外送費"

    render_card(create(:merchant, delivery_fee: 60))
    assert_text "NT$60"
  end

  test "滿額免運門檻" do
    render_card(create(:merchant, delivery_fee: 60, free_delivery_threshold: 1500))

    assert_text "NT$60（滿 NT$1,500 免運）"
  end

  test "菜單日期取最新一筆並標示新鮮度" do
    merchant = create(:merchant)
    create(:menu_item, merchant: merchant, menu_date: Date.current - 10)
    create(:menu_item, merchant: merchant, menu_date: Date.current - 3)

    render_card(merchant.reload)

    assert_text "菜單 #{(Date.current - 3).strftime('%Y-%m')}"
    assert_no_text "菜單可能過期" # 新鮮的菜單不重複放警示標籤
    assert_no_text "日期不明"
  end

  test "過期或沒有菜單：標示菜單可能過期 / 日期不明" do
    stale = create(:merchant)
    create(:menu_item, :stale, merchant: stale)
    render_card(stale.reload)
    assert_selector "span.bg-secondary", text: "菜單可能過期"

    render_card(create(:merchant))
    assert_text "尚無菜單日期"
    assert_selector "span.bg-secondary", text: "日期不明"
  end

  test "曾訂購圓點" do
    ordered = create(:merchant)
    create(:order_record, merchant: ordered)

    render_card(ordered.reload)
    assert_selector "[data-ordered=true]", text: "曾訂購"

    render_card(create(:merchant))
    assert_selector "[data-ordered=false]", text: "沒訂過"
  end

  test "右上角有收藏與下次候選兩個切換按鈕" do
    render_card(create(:merchant))

    assert_selector "button[aria-label=收藏][aria-pressed=false]"
    assert_selector "button[aria-label=下次候選][aria-pressed=false]"
  end

  test "已收藏、已加入候選的狀態反映在按鈕上" do
    render_card(create(:merchant, favorited: true, shortlisted: true))

    assert_selector "button[aria-label=收藏][aria-pressed=true]"
    assert_selector "button[aria-label=下次候選][aria-pressed=true]"
  end

  test "店名會被跳脫" do
    render_card(create(:merchant, name: "<img src=x onerror=alert(1)>"))

    assert_no_selector "img"
  end

  test "45 天內訂過：顯示「上次剛訂過」與日期；更早或沒訂過不顯示" do
    travel_to Time.zone.local(2026, 10, 27, 12, 0) do
      recent = create(:merchant)
      create(:order_record, merchant: recent, ordered_on: Date.new(2026, 10, 6))
      render_card(recent.reload)
      assert_selector "span.bg-secondary", text: "上次剛訂過 10/6"

      old = create(:merchant)
      create(:order_record, merchant: old, ordered_on: Date.new(2026, 7, 1))
      render_card(old.reload)
      assert_no_text "上次剛訂過"
      assert_selector "[data-ordered=true]", text: "曾訂購"
    end
  end
end
