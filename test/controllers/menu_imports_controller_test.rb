require "test_helper"

class MenuImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @merchant = create(:merchant, :food_and_drink, name: "阿嬤便當")
    @date = (Date.current - 5).to_s
  end

  def import_params(**overrides)
    { menu_import: { food_text: "雞腿飯 90\n排骨飯 85", drink_text: "紅茶 30", menu_date: @date }.merge(overrides) }
  end

  # --- new ---

  test "輸入表單：兩個貼上框，菜單日期必填且不預設值" do
    get new_merchant_menu_import_path(@merchant)

    assert_response :success
    assert_select "h1", "貼上菜單"
    assert_select "textarea[name='menu_import[food_text]']"
    assert_select "textarea[name='menu_import[drink_text]']"
    assert_select "input[type=date][name='menu_import[menu_date]'][required]"
    assert_select "input[type=date][name='menu_import[menu_date]'][value]", count: 0
  end

  test "返回修改：用網址參數帶回原本貼的內容" do
    get new_merchant_menu_import_path(@merchant), params: import_params

    assert_select "textarea[name='menu_import[food_text]']", text: /雞腿飯 90/
    assert_select "input[name='menu_import[menu_date]'][value=?]", @date
  end

  test "店家頁有貼上菜單的入口" do
    get merchant_path(@merchant)

    assert_select "a[href=?]", new_merchant_menu_import_path(@merchant), text: "貼上菜單"
  end

  # --- preview ---

  test "預覽：列出每一項並標示新增，但不寫入資料庫" do
    assert_no_difference "MenuItem.count" do
      post preview_merchant_menu_import_path(@merchant), params: import_params
    end

    assert_response :success
    assert_select "h1", "預覽菜單"
    assert_select "tbody tr", count: 3
    assert_select "td", text: "雞腿飯"
    assert_select "td", text: "NT$90"
    assert_select "td", text: "新增", count: 3
    assert_select "input[type=submit][value='確認匯入']"
  end

  test "預覽：已存在的品項標示更新與原價" do
    create(:menu_item, merchant: @merchant, name: "雞腿飯", category: "food", price: 80)

    post preview_merchant_menu_import_path(@merchant), params: import_params

    assert_select "td", text: /更新（原 NT\$80）/
  end

  test "預覽：解析失敗回到表單，指出行號並保留已貼內容" do
    post preview_merchant_menu_import_path(@merchant), params: import_params(food_text: "雞腿飯 90\n今日特餐")

    assert_response :unprocessable_content
    assert_select "li", text: /第 2 行「今日特餐」：找不到價格/
    assert_select "textarea[name='menu_import[food_text]']", text: /今日特餐/
  end

  test "預覽：沒填日期不能預覽" do
    post preview_merchant_menu_import_path(@merchant), params: import_params(menu_date: "")

    assert_response :unprocessable_content
    assert_select "li", text: /菜單日期不能為空白/
  end

  test "預覽：什麼都沒貼" do
    post preview_merchant_menu_import_path(@merchant), params: import_params(food_text: "", drink_text: "")

    assert_response :unprocessable_content
    assert_select "li", text: /請至少貼上一段菜單/
  end

  test "預覽頁用隱藏欄位帶回原始文字，供確認時重新解析" do
    post preview_merchant_menu_import_path(@merchant), params: import_params

    assert_select "input[type=hidden][name='menu_import[food_text]']"
    assert_select "input[type=hidden][name='menu_import[menu_date]'][value=?]", @date
    assert_select "input[type=submit][value='返回修改'][formmethod=get]"
  end

  test "預覽中的品名會被跳脫" do
    post preview_merchant_menu_import_path(@merchant), params: import_params(food_text: "<script>alert(1)</script> 90", drink_text: "")

    assert_response :success
    assert_select "script", text: /alert/, count: 0
    assert_select "td", text: "<script>alert(1)</script>"
  end

  # --- create ---

  test "確認匯入：寫入項目、套用日期、回到店家頁並提示筆數" do
    assert_difference "MenuItem.count", 3 do
      post merchant_menu_import_path(@merchant), params: import_params
    end

    assert_redirected_to merchant_path(@merchant)
    follow_redirect!
    assert_select ".alert-success", text: /已匯入 3 個菜單項目/
    assert_equal [ Date.current - 5 ], @merchant.menu_items.reload.map(&:menu_date).uniq
  end

  test "確認時會重新解析：文字有問題就不寫入，即使其中有幾行是對的" do
    assert_no_difference "MenuItem.count" do
      post merchant_menu_import_path(@merchant), params: import_params(food_text: "雞腿飯 90\n壞掉的一行")
    end

    assert_response :unprocessable_content
  end

  test "確認時沒有日期也不寫入" do
    assert_no_difference "MenuItem.count" do
      post merchant_menu_import_path(@merchant), params: import_params(menu_date: "")
    end

    assert_response :unprocessable_content
  end

  test "很舊的日期可以匯入，但之後會標示菜單可能過期" do
    post merchant_menu_import_path(@merchant), params: import_params(menu_date: (Date.current - 200).to_s)

    get merchant_path(@merchant)
    assert_select ".badge-warning", text: "菜單可能過期"
  end

  test "menu_import 參數不是 Hash 時不會報錯" do
    get new_merchant_menu_import_path(@merchant), params: { menu_import: "oops" }

    assert_response :success
  end

  test "找不到店家回 404" do
    get new_merchant_menu_import_path(merchant_id: 0)

    assert_response :not_found
  end

  test "已設定帳密時需要登入，沒登入不會寫入" do
    with_env(AUTH_ENV) do
      get new_merchant_menu_import_path(@merchant)
      assert_response :unauthorized

      assert_no_difference "MenuItem.count" do
        post merchant_menu_import_path(@merchant), params: import_params
      end
      assert_response :unauthorized
    end
  end
end
