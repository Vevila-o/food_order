require "test_helper"

module Merchants
  class InquiriesControllerTest < ActionDispatch::IntegrationTest
    setup do
      travel_to Time.zone.local(2026, 10, 22, 12, 0)
      @event = create(:event, :with_headcount, held_on: Date.new(2026, 10, 27), headcount: 18)
      @merchant = create(:merchant, :food_and_drink, :with_contacts, name: "阿嬤便當", delivery_fee: 60, free_delivery_threshold: 1500)
      @food = create(:menu_item, merchant: @merchant, name: "雞腿便當", price: 90, unit: "份")
      @drink = create(:menu_item, :drink, merchant: @merchant, name: "紅茶", price: 30, unit: "杯")
    end

    # --- GET：產生器頁 ---

    test "顯示可選品項、數量輸入、預算區、聯絡按鈕" do
      get merchant_inquiry_path(@merchant)

      assert_response :success
      assert_select "h1", "訂單詢問"
      assert_select "input[name='quantities[#{@food.id}]'][value='0']"
      assert_select "input[name='quantities[#{@drink.id}]']"
      assert_select "form[method=get][data-controller=auto-submit][data-turbo-frame=inquiry-result][data-turbo-action=replace]"
      assert_select "turbo-frame#inquiry-result"
      assert_select "span", text: "NT$1,800"
    end

    test "還沒選：訊息區是提示、聯絡按鈕停用，也不顯示「請至少選一項」錯誤" do
      get merchant_inquiry_path(@merchant)

      assert_select "pre", count: 0
      assert_select "p", text: "選好餐點後會在這裡產生訊息。"
      assert_select "button[data-action='inquiry#contact'][disabled]", count: 4
      assert_select "[role=alert]", count: 0
    end

    test "頁首顯示活動日期、人數、總預算" do
      get merchant_inquiry_path(@merchant)

      assert_select "header span", text: /10\/27（二）19:00–19:15 送達/
      assert_select "header span", text: "18 人"
      assert_select "header span", text: "總預算 NT$1,800"
    end

    test "數量放在網址：重算金額、產生訊息，聯絡按鈕可按" do
      get merchant_inquiry_path(@merchant, quantities: { @food.id => 18 })

      assert_response :success
      assert_select "input[name='quantities[#{@food.id}]'][value='18']"
      assert_select "pre[data-inquiry-message]", text: /- 雞腿便當 × 18 份/
      assert_select "pre", text: /NT\$1,620/
      assert_select "dd", text: "免外送費"
      assert_select "button[data-action='inquiry#contact']:not([disabled])", count: 4
    end

    test "品項分餐食與飲料兩組" do
      get merchant_inquiry_path(@merchant)

      assert_select "legend", text: "餐食"
      assert_select "legend", text: "飲料"
    end

    test "過期的品項不能選，另列說明並附店家頁連結" do
      stale = create(:menu_item, :stale, merchant: @merchant, name: "舊菜")

      get merchant_inquiry_path(@merchant)

      assert_select "input[name='quantities[#{stale.id}]']", count: 0
      assert_select "li", text: /舊菜/
      assert_select "a[href='#{merchant_path(@merchant)}']", text: "到店家頁確認菜單"
    end

    test "沒有可選品項：說明原因" do
      empty = create(:merchant)

      get merchant_inquiry_path(empty)

      assert_response :success
      assert_select "p", text: /目前沒有可選的餐點/
    end

    test "數量不合法：顯示錯誤、不產生訊息" do
      get merchant_inquiry_path(@merchant, quantities: { @food.id => "abc" })

      assert_response :success
      assert_select "[role=alert] li", text: /數量必須是 0 到 99/
      assert_select "pre", count: 0
      assert_select "button[data-action='inquiry#contact'][disabled]", count: 4
    end

    test "quantities 不是 Hash（?quantities=oops）不會 500" do
      get merchant_inquiry_path(@merchant, quantities: "oops")

      assert_response :success
    end

    test "外送費未知：預計金額待確認，不是 NT$0" do
      @merchant.update!(delivery_fee: nil, free_delivery_threshold: nil)

      get merchant_inquiry_path(@merchant, quantities: { @food.id => 5 })

      assert_select "dd", text: "待確認（不含外送費）"
      assert_select "dd", text: "待確認（未計入）"
    end

    test "超出預算：顯示警示色與超出金額，但訊息仍可複製" do
      get merchant_inquiry_path(@merchant, quantities: { @food.id => 18, @drink.id => 18 })

      assert_select "span.bg-warning", text: "超出預算 NT$360"
      assert_select "pre"
      assert_select "button[data-action='inquiry#contact']:not([disabled])", count: 4
    end

    test "本場其他店家的詢問單不計入合計，也不列出" do
      other = create(:merchant, name: "涼飲店")
      create(:order_inquiry, event: @event, merchant: other, subtotal: 5000, delivery_fee: 0, total: 5000)

      get merchant_inquiry_path(@merchant, quantities: { @food.id => 10 })

      assert_select "span", text: "預計合計"
      assert_select "span", text: "NT$960", minimum: 1
      assert_select "li", text: /涼飲店/, count: 0
      assert_select "span", text: /超出預算/, count: 0
    end

    test "已有詢問單：第一次打開用既有品項當預設，並顯示狀態" do
      InquiryForm.new(event: @event, merchant: @merchant, quantities: { @food.id.to_s => "7" }).save(channel: :line)

      get merchant_inquiry_path(@merchant)

      assert_select "input[name='quantities[#{@food.id}]'][value='7']"
      assert_select "strong", text: "已按聯絡按鈕"
    end

    test "已確認訂購：顯示警示，按鈕停用" do
      inquiry = InquiryForm.new(event: @event, merchant: @merchant, quantities: { @food.id.to_s => "2" }).save
      inquiry.confirm!

      get merchant_inquiry_path(@merchant)

      assert_select ".alert", text: /已確認訂購/
      assert_select "button[data-action='inquiry#contact'][disabled]", count: 4
    end

    test "活動日期已過：不擋，顯示詢問框與訊息旁提醒" do
      travel_to Time.zone.local(2026, 11, 3, 12, 0) do
        get merchant_inquiry_path(@merchant, quantities: { @food.id => 1 })

        assert_response :success
        assert_select "[data-controller=dismissible] .alert", text: /已過，要設定下一場嗎/
        assert_select "a[href='#{edit_event_path(@event)}']", text: "設定下一場"
        assert_select "button[data-action='dismissible#dismiss']", text: "先用這場繼續"
        assert_select "[role=note]", text: /已過，請確認日期再送出/
      end
    end

    test "活動日期沒過：沒有提示框" do
      get merchant_inquiry_path(@merchant)

      assert_select "[data-controller=dismissible]", count: 0
    end

    test "設定頁有填收件人與電話：寫進訊息；沒填就沒有" do
      get merchant_inquiry_path(@merchant, quantities: { @food.id => 1 })
      assert_select "pre", text: /收件人/, count: 0

      AppSetting.instance.update!(recipient_name: "王小明", recipient_phone: "0912-345-678")
      get merchant_inquiry_path(@merchant, quantities: { @food.id => 1 })
      assert_select "pre", text: /收件人：王小明，電話：0912-345-678/
    end

    test "沒有聯絡方式：提示並附來源連結" do
      bare = create(:merchant)
      create(:menu_item, merchant: bare)
      create(:merchant_source, merchant: bare, platform: "web", url: "https://example.com/menu")

      get merchant_inquiry_path(bare)

      assert_select "p", text: "尚無聯絡方式，請到來源網址查看。"
      assert_select "a[href='https://example.com/menu']"
    end

    test "沒有活動：導到設定頁並說明" do
      Event.destroy_all

      get merchant_inquiry_path(@merchant)

      assert_redirected_to edit_setting_path
      assert_match(/還沒有活動/, flash[:alert])
    end

    test "沒有人數：導到設定頁並說明，不用 0 人算" do
      Event.destroy_all
      create(:event, held_on: Date.new(2026, 10, 27))

      get merchant_inquiry_path(@merchant)

      assert_redirected_to edit_setting_path
      assert_match(/還沒有報名人數/, flash[:alert])
    end

    test "不存在的店家回 404" do
      get merchant_inquiry_path(merchant_id: 0)

      assert_response :not_found
    end

    # --- POST：儲存草稿、標為已詢問 ---

    test "儲存草稿：建立詢問單與品項，回 JSON" do
      assert_difference "OrderInquiry.count", 1 do
        post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 10, @drink.id => 8 } }, as: :json
      end
      assert_response :success

      inquiry = OrderInquiry.last
      assert_equal({ "status" => "draft", "contacted_via" => nil }, response.parsed_body.slice("status", "contacted_via"))
      assert_equal [ { "merchant_id" => @merchant.id, "status" => "draft", "contacted_via" => nil } ], response.parsed_body["inquiries"]
      assert_equal 1140, inquiry.subtotal
      assert_equal 1200, inquiry.total
      assert_equal 18, inquiry.headcount_at_creation
    end

    test "表單送出（multipart / form）也可以，JS 的 FormData 就是這種" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 3 }, channel: "line" }, headers: { "Accept" => "application/json" }

      assert_response :success
      assert_equal "sent", response.parsed_body["status"]
      assert_equal "line", response.parsed_body["contacted_via"]
    end

    test "帶管道：標為已詢問並記錄管道與時間" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 3 }, channel: "instagram" }

      inquiry = OrderInquiry.last
      assert inquiry.sent?
      assert inquiry.via_instagram?
      assert_not_nil inquiry.sent_at
    end

    test "已詢問頁看得到這張詢問單" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 3 }, channel: "line" }

      get inquiries_path

      assert_select "tbody td a[href=?]", merchant_path(@merchant), text: "阿嬤便當"
      assert_select "tbody td span.bg-soft", text: "已按聯絡按鈕"
    end

    test "再次儲存：覆蓋同一張，不新增" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 3 } }

      assert_no_difference "OrderInquiry.count" do
        post merchant_inquiry_path(@merchant), params: { quantities: { @drink.id => 5 } }
      end
      assert_equal [ "紅茶" ], OrderInquiry.last.items.map(&:name)
    end

    test "金額與訊息由伺服器重算：前端帶的 subtotal / total / message 一律忽略" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 2 }, subtotal: 1, total: 1, message_text: "假的", unit_price: 1 }

      inquiry = OrderInquiry.last
      assert_equal 180, inquiry.subtotal
      assert_equal 240, inquiry.total
      assert_not_includes inquiry.message_text, "假的"
      assert_equal 90, inquiry.items.first.unit_price
    end

    test "不認得的管道：422，不建立" do
      assert_no_difference "OrderInquiry.count" do
        post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 1 }, channel: "fax" }
      end

      assert_response :unprocessable_content
      assert_equal [ "不認得的聯絡管道" ], response.parsed_body["errors"]
    end

    test "沒選品項：422 與錯誤訊息" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 0 } }

      assert_response :unprocessable_content
      assert_includes response.parsed_body["errors"], "請至少選一項餐點"
    end

    test "沒有 quantities 參數：422，不會套用既有品項默默覆蓋" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 4 } }
      post merchant_inquiry_path(@merchant), params: {}

      assert_equal 4, OrderInquiry.last.items.first.quantity
    end

    test "已確認訂購的不能再改" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 4 } }
      OrderInquiry.last.confirm!

      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 9 } }

      assert_response :unprocessable_content
      assert_equal 4, OrderInquiry.last.items.first.quantity
    end

    test "沒有活動時儲存：422" do
      Event.destroy_all

      assert_no_difference "OrderInquiry.count" do
        post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 1 } }
      end
      assert_response :unprocessable_content
    end

    test "CSRF：開啟保護時沒有 token 的 POST 會被擋（JS 會帶 X-CSRF-Token）" do
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true

      assert_no_difference "OrderInquiry.count" do
        post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 1 } }
      end
      assert_response :unprocessable_content
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    # --- 手動編輯訊息 ---

    test "訊息區有複製與編輯（鉛筆）按鈕、隱藏的編輯區" do
      get merchant_inquiry_path(@merchant, quantities: { @food.id => 2 })

      assert_select "section button[aria-label=複製訊息][title=複製訊息][data-action='inquiry#copyOnly'] svg"
      assert_select "section button[aria-label=編輯訊息][title=編輯訊息][data-action='inquiry#editMessage'] svg"
      assert_select "div[data-message-editor][hidden] textarea[maxlength='2000']"
      assert_select "button[data-action='inquiry#finishEdit']", text: /完成/
      assert_select "button[data-action='inquiry#cancelEdit']", text: "取消"
      assert_select "pre[data-edited]", count: 0
    end

    test "儲存帶編輯過的訊息：存成這張詢問單的訊息並標記已編輯，重新打開顯示改過的版本與已編輯標籤" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 2 }, message_edits: { @merchant.id => "自訂訊息 <b>粗體</b>" } }

      assert_response :success
      inquiry = OrderInquiry.last
      assert inquiry.message_edited?
      assert_equal "自訂訊息 <b>粗體</b>", inquiry.message_text

      get merchant_inquiry_path(@merchant)
      assert_select "pre[data-edited]", text: "自訂訊息 <b>粗體</b>" # 內容會跳脫
      assert_select "b", count: 0
      assert_select "h2 span", text: "已編輯"
    end

    test "改了數量：重新產生訊息，不再是已編輯" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 2 }, message_edits: { @merchant.id => "自訂訊息" } }

      get merchant_inquiry_path(@merchant, quantities: { @food.id => 5 })

      assert_select "pre", text: /× 5 份/
      assert_select "pre[data-edited]", count: 0
      assert_select "h2 span", text: "已編輯", count: 0
    end

    test "訊息超過 2000 字：422，不儲存" do
      assert_no_difference "OrderInquiry.count" do
        post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 2 }, message_edits: { @merchant.id => "字" * 2001 } }
      end

      assert_response :unprocessable_content
      assert_includes response.parsed_body["errors"], "訊息最多 2000 字"
    end

    test "message_edits 不是 Hash 或內容不是字串：忽略，不報錯" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 2 }, message_edits: "oops" }
      assert_response :success

      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 2 }, message_edits: { @merchant.id => [ "x" ] } }
      assert_response :success
      assert_not OrderInquiry.last.message_edited?
    end

    test "按聯絡按鈕時帶編輯：訊息與標記一起存" do
      post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 2 }, channel: "line", message_edits: { @merchant.id => "要複製出去的訊息" } }

      inquiry = OrderInquiry.last
      assert inquiry.sent?
      assert_equal "要複製出去的訊息", inquiry.message_text
    end

    # --- 入口與存取保護 ---

    test "店家詳情頁底部有訂單詢問產生器入口" do
      get merchant_path(@merchant)

      assert_select "a.btn-primary[href='#{merchant_inquiry_path(@merchant)}']", text: "訂單詢問產生器"
    end

    test "需要 Basic Auth" do
      with_env(AUTH_ENV) do
        get merchant_inquiry_path(@merchant)
        assert_response :unauthorized

        post merchant_inquiry_path(@merchant), params: { quantities: { @food.id => 1 } }
        assert_response :unauthorized

        get merchant_inquiry_path(@merchant), headers: basic_auth_headers("jam", "s3cret-pass")
        assert_response :success
      end
    end
  end
end
