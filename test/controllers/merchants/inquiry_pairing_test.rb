require "test_helper"

# 兩家配對訂購（餐食店 + 飲料店）：右側面板、搭檔卡片、兩家合計、各自的訊息與聯絡按鈕、重置
module Merchants
  class InquiryPairingTest < ActionDispatch::IntegrationTest
    setup do
      travel_to Time.zone.local(2026, 10, 22, 12, 0)
      @event = create(:event, :with_headcount, held_on: Date.new(2026, 10, 27), headcount: 18)
      @meal_shop = create(:merchant, :with_contacts, name: "便當店", delivery_fee: 60, free_delivery_threshold: 1500)
      @meal = create(:menu_item, merchant: @meal_shop, name: "雞腿便當", price: 90, unit: "份")
      @drink_shop = create(:merchant, :drink_only, name: "涼飲店", delivery_fee: 50, instagram: "cool.drinks")
      @drink = create(:menu_item, :drink, merchant: @drink_shop, name: "紅茶", price: 30, unit: "杯")
    end

    def quantities(meal: 10, drink: 10) = { @meal.id => meal, @drink.id => drink }

    # --- 配對按鈕 ---

    test "餐食店：按鈕是「選飲料」；飲料店「選餐食」；餐＋飲「加選另一家」" do
      get merchant_inquiry_path(@meal_shop)
      assert_select "button[data-action='dialog#open']", text: "選飲料"

      get merchant_inquiry_path(@drink_shop)
      assert_select "button[data-action='dialog#open']", text: "選餐食"

      both = create(:merchant, :food_and_drink)
      create(:menu_item, merchant: both)
      get merchant_inquiry_path(both)
      assert_select "button[data-action='dialog#open']", text: "加選另一家"
    end

    test "右側面板是 dialog，懶載入候選清單並帶上角色" do
      get merchant_inquiry_path(@meal_shop)

      assert_select "dialog.modal-end[data-dialog-target=dialog]"
      assert_select "turbo-frame#partner-list[loading=lazy][src=?]", partners_merchant_inquiry_path(@meal_shop, role: "drink", partner_id: "")
    end

    test "沒有搭檔時：只有一個數量區，partner_id 隱藏欄位是空的，沒有重置按鈕" do
      get merchant_inquiry_path(@meal_shop)

      assert_select "input[type=hidden][name=partner_id][value='']"
      assert_select "input[type=number]", count: 1
      assert_select "button[data-action='inquiry#resetPartner']", count: 0
    end

    # --- 選了搭檔 ---

    test "選了搭檔：多一張搭檔卡片（它的品項與數量）、換一家與重置按鈕、標題帶兩家" do
      get merchant_inquiry_path(@meal_shop, partner_id: @drink_shop.id)

      assert_select "h1", "訂單詢問"
      assert_select "header", text: /便當店 ＋ 涼飲店/
      assert_select "input[type=hidden][name=partner_id][value='#{@drink_shop.id}']"
      assert_select "input[name='quantities[#{@meal.id}]']"
      assert_select "input[name='quantities[#{@drink.id}]']"
      assert_select "h2", text: "涼飲店的餐點"
      assert_select "button[data-action='dialog#open']", text: "換一家"
      assert_select "button[data-action='inquiry#resetPartner']", text: "重置，只算這家"
    end

    test "兩家合計：各家明細、合計金額與外送費" do
      get merchant_inquiry_path(@meal_shop, partner_id: @drink_shop.id, quantities: quantities(meal: 10, drink: 20))

      assert_select "ul[aria-label='各店明細'] li", count: 2
      assert_select "dd", text: "NT$1,500" # 小計 900 + 600
      assert_select "dd", text: "NT$110"  # 外送費 60 + 50
      assert_select "dd", text: "NT$1,610"
    end

    test "兩家各一則訊息、各自的聯絡按鈕，按鈕指向自己那則訊息" do
      get merchant_inquiry_path(@meal_shop, partner_id: @drink_shop.id, quantities: quantities)

      assert_select "pre#inquiry-message-#{@meal_shop.id}", text: /- 雞腿便當 × 10 份/
      assert_select "pre#inquiry-message-#{@drink_shop.id}", text: /- 紅茶 × 10 杯/
      assert_select "pre#inquiry-message-#{@meal_shop.id}", text: /紅茶/, count: 0
      assert_select "button[data-inquiry-channel-param=line][data-inquiry-message-id-param='inquiry-message-#{@meal_shop.id}'][data-inquiry-merchant-id-param='#{@meal_shop.id}']"
      assert_select "button[data-inquiry-channel-param=instagram][data-inquiry-message-id-param='inquiry-message-#{@drink_shop.id}'][data-inquiry-merchant-id-param='#{@drink_shop.id}']"
      assert_select "h2", text: "詢問訊息 · 涼飲店"
      assert_select "h2", text: "聯絡店家 · 便當店"
    end

    test "搭檔還沒選品項：只有被選的那家有訊息，另一家是提示且按鈕停用，金額不含它的外送費" do
      get merchant_inquiry_path(@meal_shop, partner_id: @drink_shop.id, quantities: quantities(meal: 10, drink: 0))

      assert_select "pre", count: 1
      assert_select "section", text: /涼飲店.*選好餐點後會在這裡產生訊息/m
      assert_select "button[data-inquiry-merchant-id-param='#{@drink_shop.id}'][disabled]"
      assert_select "dd", text: "NT$60"
      assert_select "ul[aria-label='各店明細']", count: 0
    end

    test "搭檔數量不合法：整個擋下，錯誤帶店名" do
      get merchant_inquiry_path(@meal_shop, partner_id: @drink_shop.id, quantities: { @meal.id => 5, @drink.id => "abc" })

      assert_select "[role=alert] li", text: /涼飲店：「紅茶」的數量必須是 0 到 99/
      assert_select "pre", count: 0
    end

    test "partner_id 亂填、不存在、是自己：當作沒有搭檔，不報錯" do
      [ "999999", @meal_shop.id.to_s, "abc" ].each do |id|
        get merchant_inquiry_path(@meal_shop, partner_id: id)

        assert_response :success
        assert_select "input[type=number]", count: 1
      end
      get merchant_inquiry_path(@meal_shop, partner_id: [ "1", "2" ])
      assert_response :success
    end

    # --- 重新打開時自動帶出搭檔：只有兩張都還是草稿 ---

    test "兩張都是草稿：重新打開自動帶出搭檔與數量" do
      post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: quantities(meal: 7, drink: 3) }

      get merchant_inquiry_path(@meal_shop)

      assert_select "h2", text: "涼飲店的餐點"
      assert_select "input[name='quantities[#{@meal.id}]'][value='7']"
      assert_select "input[name='quantities[#{@drink.id}]'][value='3']"
    end

    test "已經詢問（按過聯絡按鈕）：重新打開不帶搭檔，只算這一家" do
      post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: quantities, channel: "line", contact_merchant_id: @meal_shop.id }

      get merchant_inquiry_path(@meal_shop)

      assert_select "h2", text: "涼飲店的餐點", count: 0
      assert_select "input[type=number]", count: 1
      assert_select "input[name='quantities[#{@meal.id}]'][value='10']" # 該店已存的數量仍帶出
    end

    test "搭檔那家已詢問也一樣不自動帶出" do
      post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: quantities, channel: "instagram", contact_merchant_id: @drink_shop.id }

      get merchant_inquiry_path(@meal_shop)

      assert_select "h2", text: "涼飲店的餐點", count: 0
    end

    test "從「已詢問」頁的連結進來（帶 partner_id）：帶出搭檔與已存的數量" do
      post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: quantities(meal: 4, drink: 6), channel: "line" }

      get inquiries_path
      link = css_select("tbody a").find { |a| a.text == "開啟詢問" && a["href"].include?("/merchants/#{@meal_shop.id}/") }
      assert_equal merchant_inquiry_path(@meal_shop, partner_id: @drink_shop.id), link["href"]

      get link["href"]
      assert_select "h2", text: "涼飲店的餐點"
      assert_select "input[name='quantities[#{@drink.id}]'][value='6']"
    end

    test "已詢問頁：同組的兩家互相標示；沒有組顯示破折號；歷史活動沒有開啟連結" do
      post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: quantities }
      old_event = create(:event, held_on: Date.new(2026, 9, 29))
      create(:order_inquiry, event: old_event, merchant: create(:merchant, name: "舊店"))

      get inquiries_path

      assert_select "tbody td > span:last-child", text: "與 涼飲店 一組"
      assert_select "tbody td > span:last-child", text: "與 便當店 一組"
      assert_select "tbody a", text: "開啟詢問", count: 2
    end

    # --- 儲存 ---

    test "儲存草稿：兩家一起存、綁成一組" do
      assert_difference [ "OrderInquiry.count" ], 2 do
        assert_difference "OrderGroup.count", 1 do
          post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: quantities }
        end
      end

      assert_response :success
      assert_equal 2, response.parsed_body["inquiries"].size
      assert_equal OrderInquiry.find_by(merchant: @meal_shop).order_group, OrderInquiry.find_by(merchant: @drink_shop).order_group
    end

    test "按搭檔那家的聯絡按鈕：只標它為已詢問，主店維持草稿；最上層狀態是被按那家的" do
      post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: quantities, channel: "instagram", contact_merchant_id: @drink_shop.id }

      assert_equal "sent", response.parsed_body["status"]
      assert_equal "instagram", response.parsed_body["contacted_via"]
      assert OrderInquiry.find_by(merchant: @drink_shop).sent?
      assert OrderInquiry.find_by(merchant: @meal_shop).draft?
    end

    test "被按聯絡按鈕的那家沒選品項：422，什麼都不存" do
      assert_no_difference "OrderInquiry.count" do
        post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: quantities(drink: 0), channel: "instagram", contact_merchant_id: @drink_shop.id }
      end

      assert_response :unprocessable_content
    end

    test "搭檔數量不合法：422，什麼都不存" do
      assert_no_difference [ "OrderInquiry.count", "OrderGroup.count" ] do
        post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: { @meal.id => 5, @drink.id => "abc" } }
      end

      assert_response :unprocessable_content
    end

    test "contact_merchant_id 不是純量：忽略，標在主店" do
      post merchant_inquiry_path(@meal_shop), params: { quantities: quantities(drink: 0), channel: "line", contact_merchant_id: [ "x" ] }

      assert_response :success
      assert OrderInquiry.find_by(merchant: @meal_shop).sent?
    end

    # --- 重置 ---

    test "重置：這間店離組（兩張詢問單與狀態都保留），之後打開只算這一家" do
      post merchant_inquiry_path(@meal_shop), params: { partner_id: @drink_shop.id, quantities: quantities }

      assert_difference "OrderGroup.count", -1 do
        assert_no_difference "OrderInquiry.count" do
          delete partner_merchant_inquiry_path(@meal_shop)
        end
      end

      assert_response :no_content
      assert_nil OrderInquiry.find_by(merchant: @meal_shop).order_group_id
      assert_nil OrderInquiry.find_by(merchant: @drink_shop).order_group_id
      get merchant_inquiry_path(@meal_shop)
      assert_select "input[type=number]", count: 1
    end

    test "重置：本來就沒有組也不報錯（冪等）" do
      delete partner_merchant_inquiry_path(@meal_shop)
      delete partner_merchant_inquiry_path(@meal_shop)

      assert_response :no_content
    end

    test "重置需要 Basic Auth" do
      with_env(AUTH_ENV) do
        delete partner_merchant_inquiry_path(@meal_shop)
        assert_response :unauthorized
      end
    end

    # --- 右側面板的候選清單 ---

    test "選飲料：列出賣飲料的店（含餐＋飲），排除自己、19:00 明確不外送、只有餐的店" do
      both = create(:merchant, :food_and_drink, name: "餐飲店")
      create(:menu_item, merchant: both)
      create(:merchant, :drink_only, name: "不送店", delivers_at_19: "no")
      create(:merchant, name: "只有餐的店")

      get partners_merchant_inquiry_path(@meal_shop, role: "drink")

      assert_response :success
      assert_select "turbo-frame#partner-list article h3", count: 2
      assert_select "article h3", text: "涼飲店"
      assert_select "article h3", text: "餐飲店"
      assert_select "article h3", text: "不送店", count: 0
      assert_select "article h3", text: "便當店", count: 0
    end

    test "不認得的 role 當作 any；role 不是字串也不會報錯" do
      get partners_merchant_inquiry_path(@meal_shop, role: "bogus")
      assert_select "article h3", text: "涼飲店"

      get partners_merchant_inquiry_path(@meal_shop, role: [ "x" ])
      assert_response :success
    end

    test "目前選的搭檔標示為目前選擇；這場已有詢問單的店標示" do
      create(:order_inquiry, event: @event, merchant: @drink_shop)

      get partners_merchant_inquiry_path(@meal_shop, role: "drink", partner_id: @drink_shop.id)

      assert_select "article.ring-primary button[disabled]", text: "目前選擇"
      assert_select "article span", text: "已有詢問單"
    end

    test "候選清單的按鈕交給 inquiry controller；菜單過期的店不能選" do
      stale = create(:merchant, :drink_only, name: "過期店")
      create(:menu_item, :stale, merchant: stale)

      get partners_merchant_inquiry_path(@meal_shop, role: "drink")

      assert_select "button[data-action='inquiry#pickPartner'][data-inquiry-partner-id-param='#{@drink_shop.id}']:not([disabled])"
      assert_select "article", text: /過期店/ do
        assert_select "button[disabled]", text: "菜單可能過期"
      end
    end

    test "沒有候選店家：說明" do
      @drink_shop.destroy!

      get partners_merchant_inquiry_path(@meal_shop, role: "drink")

      assert_select "p", text: "沒有可以搭配的店家"
    end

    test "候選清單需要 Basic Auth，不存在的店家 404" do
      with_env(AUTH_ENV) do
        get partners_merchant_inquiry_path(@meal_shop)
        assert_response :unauthorized
      end
      get partners_merchant_inquiry_path(merchant_id: 0)
      assert_response :not_found
    end
  end
end
