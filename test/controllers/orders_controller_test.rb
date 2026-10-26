require "test_helper"

# 已訂購：補登（手動新增）過去訂過的店家、刪除補登紀錄
class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.local(2026, 10, 27, 12, 0)
    @merchant = create(:merchant, name: "阿嬤便當")
  end

  # --- 新增表單 ---

  test "已訂購頁有補登入口（頁首的加號）" do
    get orders_path

    assert_select "header a[aria-label=補登訂購][href=?]", new_order_path
  end

  test "補登表單：店家下拉、日期預設今天且不能選未來、人數、金額、備註" do
    get new_order_path

    assert_response :success
    assert_select "h1", "補登訂購"
    assert_select "select[name='order_record[merchant_id]'] option", text: "阿嬤便當"
    assert_select "input[type=date][name='order_record[ordered_on]'][value='2026-10-27'][max='2026-10-27']"
    assert_select "input[name='order_record[headcount]']"
    assert_select "input[name='order_record[total]']"
    assert_select "input[name='order_record[note]'][maxlength='200']"
  end

  test "從店家頁的補登連結進來：帶入該店" do
    get new_order_path(merchant_id: @merchant.id)

    assert_select "select option[selected][value=?]", @merchant.id.to_s, text: "阿嬤便當"
  end

  test "店家頁有補登訂購連結" do
    get merchant_path(@merchant)

    assert_select "a[href=?]", new_order_path(merchant_id: @merchant.id), text: "補登訂購"
  end

  # --- 補登 ---

  test "補登：建立手動紀錄，店家變成曾訂購" do
    assert_not @merchant.ordered_before?

    assert_difference "OrderRecord.count", 1 do
      post orders_path, params: { order_record: { merchant_id: @merchant.id, ordered_on: "2026-09-15", headcount: "18", total: "1620", note: "很好吃" } }
    end

    assert_redirected_to orders_path
    assert_response :see_other
    record = OrderRecord.last
    assert_equal [ @merchant, Date.new(2026, 9, 15), 18, 1620, "很好吃", "manual" ], [ record.merchant, record.ordered_on, record.headcount, record.total, record.note, record.source ]
    assert @merchant.reload.ordered_before?
    follow_redirect!
    assert_select ".alert", text: /已補登「阿嬤便當」/
    assert_select "tbody td a", text: "阿嬤便當"
  end

  test "補登：人數、金額、備註可以不填（金額留空是 NULL，不是 0）" do
    post orders_path, params: { order_record: { merchant_id: @merchant.id, ordered_on: "2026-09-15", headcount: "", total: "", note: "" } }

    record = OrderRecord.last
    assert_nil record.headcount
    assert_nil record.total
  end

  test "補登：來源一律是手動，不能由參數指定" do
    post orders_path, params: { order_record: { merchant_id: @merchant.id, ordered_on: "2026-09-15", source: "inquiry" } }

    assert_equal "manual", OrderRecord.last.source
  end

  test "補登：沒選店家或沒填日期要報錯，並保留已填內容" do
    assert_no_difference "OrderRecord.count" do
      post orders_path, params: { order_record: { merchant_id: "", ordered_on: "", note: "備註內容" } }
    end

    assert_response :unprocessable_content
    assert_select ".alert li", text: /店家/
    assert_select ".alert li", text: /訂購日期/
    assert_select "input[name='order_record[note]'][value='備註內容']"
  end

  test "補登：日期不能晚於今天" do
    assert_no_difference "OrderRecord.count" do
      post orders_path, params: { order_record: { merchant_id: @merchant.id, ordered_on: "2026-10-28" } }
    end

    assert_response :unprocessable_content
    assert_select ".alert li", text: /不可晚於今天/
  end

  test "補登：人數、金額不能是負數或亂填" do
    [ { headcount: "-1" }, { total: "-5" }, { headcount: "abc" }, { total: "1.5" } ].each do |bad|
      assert_no_difference "OrderRecord.count" do
        post orders_path, params: { order_record: { merchant_id: @merchant.id, ordered_on: "2026-09-15" }.merge(bad) }
      end
      assert_response :unprocessable_content, bad.inspect
    end
  end

  test "補登：不存在的店家被拒絕，缺少參數回 400" do
    post orders_path, params: { order_record: { merchant_id: "999999", ordered_on: "2026-09-15" } }
    assert_response :unprocessable_content

    post orders_path, params: {}
    assert_response :bad_request
  end

  # --- 刪除 ---

  test "已訂購頁：手動補登的有刪除按鈕，詢問單產生的沒有" do
    manual = create(:order_record, merchant: @merchant, source: "manual")
    event = create(:event, held_on: Date.new(2026, 10, 27))
    inquiry = create(:order_inquiry, event: event, merchant: create(:merchant), status: "sent", sent_at: Time.current)
    inquiry.confirm!

    get orders_path

    assert_select "tbody form[action=?] button[aria-label^=刪除補登紀錄] svg", order_path(manual)
    assert_select "tbody form[action=?]", order_path(inquiry.order_record), count: 0
    assert_select "tbody form[data-turbo-confirm]", count: 1
  end

  test "刪除補登紀錄" do
    record = create(:order_record, merchant: @merchant, source: "manual")

    assert_difference "OrderRecord.count", -1 do
      delete order_path(record)
    end

    assert_redirected_to orders_path
    assert_not @merchant.reload.ordered_before?
  end

  test "詢問單產生的紀錄不能在這裡刪，提示到已詢問取消" do
    event = create(:event, held_on: Date.new(2026, 10, 27))
    inquiry = create(:order_inquiry, event: event, merchant: @merchant, status: "sent", sent_at: Time.current)
    inquiry.confirm!

    assert_no_difference "OrderRecord.count" do
      delete order_path(inquiry.order_record)
    end

    assert_redirected_to orders_path
    assert_match(/已詢問/, flash[:alert])
  end

  test "刪除不存在的紀錄回 404" do
    delete order_path(id: 0)

    assert_response :not_found
  end

  test "需要 Basic Auth" do
    with_env(AUTH_ENV) do
      get new_order_path
      assert_response :unauthorized

      post orders_path, params: { order_record: { merchant_id: @merchant.id, ordered_on: "2026-09-15" } }
      assert_response :unauthorized
    end
  end

  # --- 上次剛訂過 ---

  test "首頁卡片：45 天內訂過顯示「上次剛訂過」，更早的不顯示" do
    create(:order_record, merchant: @merchant, ordered_on: Date.new(2026, 10, 6)) # 21 天前
    old = create(:merchant, name: "很久以前")
    create(:order_record, merchant: old, ordered_on: Date.new(2026, 8, 1))
    create(:merchant, name: "沒訂過")

    get root_path

    assert_select "article", text: /阿嬤便當/ do
      assert_select "span", text: "上次剛訂過 10/6"
    end
    assert_select "article", text: /很久以前/ do
      assert_select "span", text: /上次剛訂過/, count: 0
    end
    assert_select "span", text: /上次剛訂過/, count: 1
  end

  test "店家頁與產生器頁也提示上次剛訂過" do
    create(:order_record, merchant: @merchant, ordered_on: Date.new(2026, 10, 6))

    get merchant_path(@merchant)
    assert_select "header span", text: "上次剛訂過 10/6"

    event = create(:event, :with_headcount, held_on: Date.new(2026, 11, 3), headcount: 18)
    create(:menu_item, merchant: @merchant)
    get merchant_inquiry_path(@merchant)
    assert_select "header span", text: "阿嬤便當：上次剛訂過 10/6"
    assert event.persisted?
  end

  test "候選面板的店家卡也提示上次剛訂過" do
    other = create(:merchant, :drink_only, name: "涼飲店")
    create(:menu_item, merchant: other)
    create(:order_record, merchant: other, ordered_on: Date.new(2026, 10, 20))

    get partners_merchant_inquiry_path(@merchant, role: "drink")

    assert_select "article span", text: "上次剛訂過 10/20"
  end

  test "詢問單確認訂購後：這家立刻顯示上次剛訂過（紀錄日期是活動日）" do
    event = create(:event, held_on: Date.new(2026, 11, 3))
    inquiry = create(:order_inquiry, event: event, merchant: @merchant, status: "sent", sent_at: Time.current)
    inquiry.confirm!

    get root_path

    assert_select "article span", text: "上次剛訂過 11/3"
  end
end
