require "test_helper"

class MerchantsControllerTest < ActionDispatch::IntegrationTest
  def valid_params(**overrides)
    { merchant: { name: "阿嬤便當", offers_food: "1", offers_drink: "0", delivers_at_19: "unknown", delivers_to_daan: "unknown" }.merge(overrides) }
  end

  # --- index ---

  test "沒有店家時顯示空狀態與新增連結" do
    get merchants_path

    assert_response :success
    assert_select "a[href=?]", new_merchant_path, text: "新增店家"
    assert_select "article", count: 0
  end

  test "列出店家卡片，收藏的排前面" do
    normal = create(:merchant, name: "普通店")
    favorite = create(:merchant, name: "收藏店", favorited: true)

    get merchants_path

    assert_select "article", count: 2
    names = css_select("article h2 a").map(&:text)
    assert_equal [ favorite.name, normal.name ], names
  end

  # --- index 篩選 ---

  test "篩選條件放在網址：只列出符合的店家，並顯示筆數與條件數" do
    create(:merchant, name: "免運店", delivery_fee: 0)
    create(:merchant, name: "收費店", delivery_fee: 60)

    get merchants_path, params: { filter: { free_delivery: "1" } }

    assert_select "article", count: 1
    assert_select "article h2 a", text: "免運店"
    assert_select "turbo-frame#merchant-list h2", text: /符合條件\s*1\s*家/
    assert_select "turbo-frame#merchant-list a", text: "清除篩選"
  end

  test "篩選列帶入目前條件：膠囊與抽屜共用同一個表單" do
    get merchants_path, params: { filter: { favorited: "1", kinds: [ "food_and_drink", "food_only" ], sort: "name" } }

    assert_select "form#filter-form input[name='filter[favorited]'][checked]", count: 1
    assert_select "form#filter-form input[name='filter[kinds][]'][value=food_and_drink][checked]", count: 1
    assert_select "dialog input[name='filter[kinds][]'][value=food_only][checked][form=filter-form]", count: 1
    assert_select "dialog select[form=filter-form] option[value=name][selected]"
    assert_select "dialog button[type=submit][form=filter-form]", text: "套用"
  end

  test "「更多篩選」按鈕顯示抽屜裡已啟用的條件數" do
    get merchants_path, params: { filter: { favorited: "1", daan: "1", never_ordered: "1" } }

    assert_select "button[data-action='dialog#open']", text: /更多篩選 \(2\)/
  end

  test "沒有抽屜條件時「更多篩選」不顯示數字" do
    get merchants_path, params: { filter: { favorited: "1" } }

    assert_select "button[data-action='dialog#open']", text: /\A\s*更多篩選\s*\z/
  end

  test "沒有符合條件：說明哪些資料不會被篩掉，並提供清除" do
    create(:merchant)

    get merchants_path, params: { filter: { favorited: "1" } }

    assert_select "article", count: 0
    assert_select "p", text: "沒有符合條件的店家"
    assert_select "div", text: /沒填的店會照常顯示/
  end

  test "完全沒有店家時提示新增，而不是說沒有符合條件" do
    get merchants_path

    assert_select "p", text: "還沒有店家"
    assert_select "a[href=?]", new_merchant_path, text: "新增店家"
  end

  test "排序：依每人估價低到高" do
    create(:merchant, name: "貴", price_per_person_min: 120)
    create(:merchant, name: "便宜", price_per_person_min: 80)

    get merchants_path, params: { filter: { sort: "price" } }

    assert_equal [ "便宜", "貴" ], css_select("article h2 a").map(&:text)
  end

  test "不認得的篩選參數被忽略，不會報錯" do
    create(:merchant)

    get merchants_path, params: { filter: { kinds: [ "evil" ], sort: "random", hack: "1" }, other: "x" }

    assert_response :success
    assert_select "article", count: 1
  end

  test "篩選參數不是 Hash 時也不會報錯" do
    get merchants_path, params: { filter: "oops" }

    assert_response :success
  end

  test "卡片連結跳出 Turbo Frame，並由 detail-link 決定是否開新分頁" do
    create(:merchant)

    get merchants_path

    assert_select "article h2 a[data-turbo-frame=_top][data-controller=detail-link]"
  end

  test "只認「本場預算」作為滿額免運的比較基準" do
    create(:event, :with_headcount, headcount: 18, held_on: Date.current + 3)
    create(:merchant, name: "門檻 1500", delivery_fee: 60, free_delivery_threshold: 1500)
    create(:merchant, name: "門檻 3000", delivery_fee: 60, free_delivery_threshold: 3000)

    get merchants_path, params: { filter: { free_delivery: "1" } }

    assert_equal [ "門檻 1500" ], css_select("article h2 a").map(&:text)
  end

  test "根路徑是店家列表" do
    get root_path

    assert_response :success
    assert_select "h1", "找今晚的餐"
  end

  # --- show ---

  test "顯示店家完整資訊" do
    merchant = create(:merchant, :with_contacts, :food_and_drink, name: "阿嬤便當", address: "台北市大安區和平東路", district: "大安區", delivery_fee: 0)
    create(:menu_item, merchant: merchant, name: "雞腿飯", price: 90)

    get merchant_path(merchant)

    assert_response :success
    assert_select "h1", "阿嬤便當"
    assert_select "a[href=?]", "https://line.me/R/ti/p/@rubyjam", text: "LINE"
    assert_select "a[href=?]", "tel:0223456789", text: "電話"
    assert_select "li", text: /雞腿飯/
    assert_select "button", text: "確認菜單仍有效"
    assert_select "section", text: /建議搭配/
  end

  test "沒有任何聯絡方式時提示到來源網址查看" do
    get merchant_path(create(:merchant))

    assert_select "p", text: "尚無聯絡方式，請到來源網址查看。"
  end

  test "來源網址顯示為連結並開新分頁（帶 noopener）" do
    merchant = create(:merchant)
    create(:merchant_source, merchant: merchant, url: "https://example.com/menu")

    get merchant_path(merchant)

    assert_select "a[href='https://example.com/menu'][rel~=noopener]"
  end

  test "菜單項目標示新鮮度；過期的標示菜單可能過期" do
    merchant = create(:merchant)
    create(:menu_item, :stale, merchant: merchant)

    get merchant_path(merchant)

    assert_select "span.bg-secondary", text: "菜單可能過期"
  end

  test "整箱飲料顯示可供人數與每人單價" do
    merchant = create(:merchant, :drink_only)
    create(:menu_item, :drink, merchant: merchant, name: "紅茶一箱", price: 360, unit: "箱", servings: 24)

    get merchant_path(merchant)

    assert_select "div", text: /可供 24 人，約每人 NT\$15/
  end

  test "找不到店家回 404" do
    get merchant_path(id: 0)

    assert_response :not_found
  end

  test "店名中的 HTML 會被跳脫（防 XSS）" do
    merchant = create(:merchant, name: "<script>alert(1)</script>")

    get merchant_path(merchant)
    assert_select "script", text: /alert/, count: 0

    get merchants_path
    assert_select "script", text: /alert/, count: 0
  end

  # --- new / create ---

  test "新增表單：欄位、巢狀菜單與來源的範本" do
    get new_merchant_path

    assert_response :success
    assert_select "form input[name='merchant[name]']"
    assert_select "select[name='merchant[delivers_at_19]'] option", text: "待確認"
    assert_select "template[data-nested-form-target=template]", count: 2
    assert_select "input[type=number][name='merchant[delivery_fee]'][min='0']"
  end

  test "新增店家（含菜單與來源網址）" do
    assert_difference [ "Merchant.count", "MenuItem.count", "MerchantSource.count" ], 1 do
      post merchants_path, params: valid_params(
        phone: "02-2345-6789",
        menu_items_attributes: { "0" => { name: "雞腿飯", category: "food", price: "90", menu_date: Date.current.to_s } },
        sources_attributes: { "0" => { platform: "manual", url: "https://example.com/menu" } }
      )
    end

    merchant = Merchant.last
    assert_redirected_to merchant_path(merchant)
    follow_redirect!
    assert_select ".alert-success", text: "已新增店家"
    assert_equal [ "雞腿飯" ], merchant.menu_items.map(&:name)
  end

  test "完全空白的菜單列與來源列會被忽略" do
    assert_difference "Merchant.count", 1 do
      assert_no_difference [ "MenuItem.count", "MerchantSource.count" ] do
        post merchants_path, params: valid_params(
          menu_items_attributes: { "0" => { name: "", category: "food", price: "", menu_date: "" } },
          sources_attributes: { "0" => { platform: "manual", url: "" } }
        )
      end
    end
  end

  test "驗證失敗：回到表單、顯示中文錯誤、保留已填內容" do
    assert_no_difference "Merchant.count" do
      post merchants_path, params: valid_params(name: "", address: "和平東路", offers_food: "0", offers_drink: "0")
    end

    assert_response :unprocessable_content
    assert_select ".alert-warning", text: /請修正以下問題/
    assert_select "li", text: /店名不能為空白/
    assert_select "li", text: /至少要販售餐食或飲料其中一種/
    assert_select "input[name='merchant[address]'][value='和平東路']"
  end

  test "只填品名沒填價格：該列顯示錯誤" do
    post merchants_path, params: valid_params(menu_items_attributes: { "0" => { name: "雞腿飯", category: "food", price: "" } })

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /價格/
  end

  test "非 https 的來源網址被拒絕" do
    [ "http://example.com", "javascript:alert(1)", "https://192.168.1.1/menu" ].each do |url|
      assert_no_difference "Merchant.count" do
        post merchants_path, params: valid_params(sources_attributes: { "0" => { platform: "manual", url: url } })
      end
      assert_response :unprocessable_content
    end
  end

  test "電話與既有店家相同：存檔成功但提醒可能重複" do
    create(:merchant, name: "既有店家", phone: "02-2345-6789")

    post merchants_path, params: valid_params(phone: "(02) 2345 6789")

    assert_redirected_to merchant_path(Merchant.last)
    follow_redirect!
    assert_select ".alert-warning", text: /既有店家.*可能是重複店家/
  end

  test "收藏、候選、驗證時間不能從表單大量指定" do
    post merchants_path, params: valid_params(favorited: "1", shortlisted: "1", last_verified_at: "2026-01-01", shortlist_position: "1")

    merchant = Merchant.last
    assert_not merchant.favorited
    assert_not merchant.shortlisted
    assert_nil merchant.last_verified_at
  end

  # --- edit / update ---

  test "編輯表單帶入既有資料與菜單" do
    merchant = create(:merchant, name: "阿嬤便當")
    create(:menu_item, merchant: merchant, name: "雞腿飯")

    get edit_merchant_path(merchant)

    assert_response :success
    assert_select "input[name='merchant[name]'][value='阿嬤便當']"
    assert_select "input[name$='[name]'][value='雞腿飯']"
  end

  test "更新店家資料" do
    merchant = create(:merchant, name: "舊名")

    patch merchant_path(merchant), params: valid_params(name: "新名", delivery_fee: "60")

    assert_redirected_to merchant_path(merchant)
    assert_equal [ "新名", 60 ], merchant.reload.then { |m| [ m.name, m.delivery_fee ] }
  end

  test "外送費清空後存成 NULL，不是 0" do
    merchant = create(:merchant, delivery_fee: 60)

    patch merchant_path(merchant), params: valid_params(delivery_fee: "")

    assert_nil merchant.reload.delivery_fee
  end

  test "更新時可新增、修改與刪除菜單項目" do
    merchant = create(:merchant)
    keep = create(:menu_item, merchant: merchant, name: "排骨飯", price: 85)
    drop = create(:menu_item, merchant: merchant, name: "舊菜")

    patch merchant_path(merchant), params: valid_params(
      menu_items_attributes: {
        "0" => { id: keep.id, name: "排骨飯", category: "food", price: "90", menu_date: Date.current.to_s },
        "1" => { id: drop.id, _destroy: "1" },
        "2" => { name: "紅茶", category: "drink", price: "30", menu_date: Date.current.to_s }
      }
    )

    assert_redirected_to merchant_path(merchant)
    assert_equal({ "排骨飯" => 90, "紅茶" => 30 }, merchant.menu_items.reload.to_h { |item| [ item.name, item.price ] })
  end

  test "更新驗證失敗時回到編輯表單" do
    merchant = create(:merchant)

    patch merchant_path(merchant), params: valid_params(name: "")

    assert_response :unprocessable_content
    assert_select "h1", "編輯店家"
  end

  # --- destroy ---

  test "刪除店家與其菜單" do
    merchant = create(:merchant)
    create(:menu_item, merchant: merchant)

    assert_difference [ "Merchant.count", "MenuItem.count" ], -1 do
      delete merchant_path(merchant)
    end

    assert_redirected_to merchants_path
    follow_redirect!
    assert_select ".alert-success", text: /已刪除/
  end

  test "有詢問單的店家不可刪除，並說明原因" do
    inquiry = create(:order_inquiry)

    assert_no_difference "Merchant.count" do
      delete merchant_path(inquiry.merchant)
    end

    assert_redirected_to merchant_path(inquiry.merchant)
    follow_redirect!
    assert_select ".alert-warning", text: /已有詢問單或訂購紀錄，無法刪除/
  end

  test "有訂購紀錄的店家不可刪除" do
    record = create(:order_record)

    assert_no_difference "Merchant.count" do
      delete merchant_path(record.merchant)
    end
  end

  # --- verify_menu ---

  test "確認菜單仍有效：所有項目日期改為今天" do
    merchant = create(:merchant)
    stale = create(:menu_item, :stale, merchant: merchant)

    post verify_menu_merchant_path(merchant)

    assert_redirected_to merchant_path(merchant)
    assert_equal Date.current, stale.reload.menu_date
    assert_not_nil merchant.reload.last_verified_at
  end

  # --- 存取保護 ---

  test "已設定帳密時，所有店家頁面都需要登入" do
    merchant = create(:merchant)

    with_env(AUTH_ENV) do
      get merchants_path
      assert_response :unauthorized
      get merchant_path(merchant)
      assert_response :unauthorized
      post merchants_path, params: valid_params
      assert_response :unauthorized
      delete merchant_path(merchant)
      assert_response :unauthorized
      assert Merchant.exists?(merchant.id)
    end
  end
end
