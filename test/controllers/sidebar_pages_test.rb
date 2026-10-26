require "test_helper"

# 側欄與它連到的五個頁面：瀏覽歷史、收藏、下次訂購、已詢問、已訂購
class SidebarPagesTest < ActionDispatch::IntegrationTest
  # --- 側欄本身（每一頁都有） ---

  test "每個頁面都有桌機側欄與手機抽屜，各六個連結" do
    [ root_path, history_path, favorites_path, shortlist_path, inquiries_path, orders_path, new_merchant_path ].each do |path|
      get path

      assert_response :success, path
      assert_select "aside[aria-label=側欄] nav a", count: 6
      assert_select "dialog.modal-start nav a", count: 6
      assert_select "dialog.modal-start button[aria-label=關閉選單]"
    end
  end

  test "手機選單按鈕開的是外層的 dialog controller" do
    get root_path

    assert_select "div[data-controller=dialog] > header button[data-action='dialog#open'][aria-label=開啟選單]"
    assert_select "div[data-controller=dialog] > dialog[data-dialog-target=dialog]"
  end

  test "目前頁面標示 aria-current" do
    { history_path => "瀏覽歷史", favorites_path => "收藏", shortlist_path => "下次訂購", inquiries_path => "已詢問", orders_path => "已訂購", root_path => "全部店家" }.each do |path, label|
      get path

      assert_select "aside a[aria-current=page]", text: /#{label}/, count: 1
    end
  end

  test "店家詳情頁屬於全部店家" do
    get merchant_path(create(:merchant))

    assert_select "aside a[aria-current=page]", text: /全部店家/
  end

  test "側欄顯示各項目的數量" do
    create(:merchant, favorited: true)
    create(:merchant, favorited: true)
    create(:merchant, shortlisted: true, shortlist_position: 1)
    viewed = create(:merchant)
    viewed.record_view!
    create(:order_inquiry)
    create(:order_record)
    create(:order_record)
    create(:order_record)

    get root_path

    assert_select "aside a", text: /瀏覽歷史\s*1/
    assert_select "aside a", text: /收藏\s*2/
    assert_select "aside a", text: /下次訂購\s*1/
    assert_select "aside a", text: /已詢問\s*1/
    assert_select "aside a", text: /已訂購\s*3/
  end

  test "瀏覽歷史的數量以 20 為上限" do
    21.times { create(:merchant).record_view! }

    get root_path

    assert_select "aside a", text: /瀏覽歷史\s*20/
  end

  test "沒有資料時不顯示數量" do
    get root_path

    assert_select "aside a", text: /\A\s*收藏\s*\z/
  end

  # --- 瀏覽歷史 ---

  test "瀏覽歷史：最近看的在前，沒看過的不列入" do
    old = create(:merchant, name: "舊的")
    recent = create(:merchant, name: "新的")
    create(:merchant, name: "沒看過")
    old.record_view!(at: 2.days.ago)
    recent.record_view!(at: 1.minute.ago)

    get history_path

    assert_select "h1", "瀏覽歷史"
    assert_equal [ "新的", "舊的" ], css_select("article h2 a").map(&:text)
  end

  test "瀏覽歷史最多 20 間" do
    21.times { |i| create(:merchant, name: "店 #{i}").record_view!(at: (30 - i).minutes.ago) }

    get history_path

    assert_select "article", count: 20
  end

  test "打開詳情頁後會出現在瀏覽歷史" do
    merchant = create(:merchant, name: "剛看過")

    get merchant_path(merchant)
    get history_path

    assert_select "article h2 a", text: "剛看過"
  end

  test "瀏覽歷史沒有資料：提示並引導去看店家" do
    get history_path

    assert_select "p", text: "還沒有瀏覽紀錄"
    assert_select "a[href=?]", merchants_path, text: "去看看店家"
  end

  test "瀏覽歷史的卡片也有收藏與候選按鈕" do
    create(:merchant).record_view!

    get history_path

    assert_select "article button[aria-label=收藏]"
    assert_select "article button[aria-label=下次候選]"
  end

  # --- 收藏 ---

  test "收藏：只列出已收藏的店家" do
    create(:merchant, name: "收藏的", favorited: true)
    create(:merchant, name: "沒收藏")

    get favorites_path

    assert_select "h1", "收藏"
    assert_equal [ "收藏的" ], css_select("article h2 a").map(&:text)
    assert_select "article button[aria-label=收藏][aria-pressed=true]"
  end

  test "收藏沒有資料：說明怎麼收藏" do
    get favorites_path

    assert_select "p", text: "還沒有收藏的店家"
    assert_select "div", text: /星號/
  end

  # --- 下次訂購 ---

  test "下次訂購：只列出下次候選的店家，依加入順序（不是收藏優先）" do
    create(:merchant, name: "後加的", shortlisted: true, shortlist_position: 2, favorited: true)
    create(:merchant, name: "先加的", shortlisted: true, shortlist_position: 1)
    create(:merchant, name: "沒加入", favorited: true)

    get shortlist_path

    assert_select "h1", "下次訂購"
    assert_equal %w[先加的 後加的], css_select("article h2 a").map(&:text)
    assert_select "article button[aria-label=下次候選][aria-pressed=true]", count: 2
  end

  test "下次訂購：每間店有順位、往前 / 往後按鈕（最前與最後停用）與備註表單" do
    first = create(:merchant, name: "先加的", shortlisted: true, shortlist_position: 1, shortlist_note: "上次太鹹")
    last = create(:merchant, name: "後加的", shortlisted: true, shortlist_position: 2)

    get shortlist_path

    assert_select "ol[aria-label=候選名單] > li", count: 2
    assert_select "li#shortlist_item_#{first.id} span[aria-label='第 1 順位']", text: "1"
    assert_select "li#shortlist_item_#{last.id} span[aria-label='第 2 順位']", text: "2"
    assert_select "li#shortlist_item_#{first.id} button[disabled][aria-label='先加的往前一位']"
    assert_select "li#shortlist_item_#{first.id} form[action=?] button:not([disabled])", move_merchant_shortlist_path(first, direction: "down")
    assert_select "li#shortlist_item_#{last.id} button[disabled][aria-label='後加的往後一位']"
    assert_select "li#shortlist_item_#{first.id} textarea[name=shortlist_note]", text: /上次太鹹/
    assert_select "li#shortlist_item_#{last.id} form[action=?] input[type=submit][value=儲存備註]", merchant_shortlist_path(last)
    assert_select "meta[name=turbo-refresh-method][content=morph]"
    assert_select "meta[name=turbo-refresh-scroll][content=preserve]"
  end

  test "下次訂購沒有資料：說明怎麼加入" do
    get shortlist_path

    assert_select "p", text: "還沒有下次要訂的店家"
    assert_select "div", text: /書籤/
  end

  # --- 已詢問 ---

  test "已詢問：每筆一行，含活動月份、店家、狀態、管道、人數、金額" do
    merchant = create(:merchant, name: "阿嬤便當")
    event = create(:event, held_on: Date.new(2026, 10, 27))
    create(:order_inquiry, event: event, merchant: merchant, status: "sent", contacted_via: "line",
                           headcount_at_creation: 18, total: 1620, subtotal: 1620)

    get inquiries_path

    assert_select "h1", "已詢問"
    assert_select "table caption", text: "已詢問的紀錄"
    assert_select "tbody tr", count: 1
    assert_select "tbody td > span:last-child", text: "2026 年 10 月"
    assert_select "tbody td a[href=?]", merchant_path(merchant), text: "阿嬤便當"
    assert_select "tbody td span.bg-soft", text: "已按聯絡按鈕"
    assert_select "tbody td > span:last-child", text: "LINE"
    assert_select "tbody td > span:last-child", text: "18 人"
    assert_select "tbody td > span:last-child", text: "NT$1,620"
  end

  test "已詢問：狀態標籤的顏色、外送費未知顯示待確認而不是 NT$0" do
    create(:order_inquiry, status: "confirmed")
    create(:order_inquiry, :fee_unknown, event: create(:event, held_on: Date.new(2026, 11, 17)))

    get inquiries_path

    assert_select "tbody td span.bg-primary", text: "已確認訂購"
    assert_select "tbody td span.bg-base-200", text: "草稿"
    assert_select "tbody td span.bg-secondary", text: "待確認"
    assert_select "tbody td > span:last-child", text: "NT$0", count: 0
  end

  test "已詢問：沒按過聯絡按鈕時管道顯示破折號" do
    create(:order_inquiry)

    get inquiries_path

    assert_select "tbody td > span:last-child", text: "—"
  end

  test "已詢問：最近建立的在前" do
    create(:order_inquiry, merchant: create(:merchant, name: "較早"), created_at: 3.days.ago)
    create(:order_inquiry, merchant: create(:merchant, name: "較晚"), created_at: 1.hour.ago, event: create(:event, held_on: Date.new(2026, 11, 17)))

    get inquiries_path

    assert_equal [ "較晚", "較早" ], css_select("tbody td a").map(&:text).reject { |text| text == "開啟詢問" }
  end

  test "已詢問沒有資料" do
    get inquiries_path

    assert_select "p", text: "還沒有詢問紀錄"
    assert_select "table", count: 0
  end

  # --- 已訂購 ---

  test "已訂購：日期、店家、人數、金額、來源、備註" do
    merchant = create(:merchant, name: "阿嬤便當")
    create(:order_record, merchant: merchant, ordered_on: Date.new(2026, 9, 15), headcount: 16, total: 1500, source: "manual", note: "很好吃")

    get orders_path

    assert_select "h1", "已訂購"
    assert_select "tbody td > span:last-child", text: /2026年09月15日/
    assert_select "tbody td a[href=?]", merchant_path(merchant), text: "阿嬤便當"
    assert_select "tbody td > span:last-child", text: "16 人"
    assert_select "tbody td > span:last-child", text: "NT$1,500"
    assert_select "tbody td > span:last-child", text: "手動補登"
    assert_select "tbody td > span:last-child", text: "很好吃"
  end

  test "已訂購：日期不明的顯示日期不明並排最後，沒填的欄位顯示破折號" do
    create(:order_record, merchant: create(:merchant, name: "不記得"), ordered_on: nil)
    create(:order_record, merchant: create(:merchant, name: "很久以前"), ordered_on: Date.new(2026, 1, 5))
    create(:order_record, merchant: create(:merchant, name: "最近"), ordered_on: Date.new(2026, 9, 15))

    get orders_path

    assert_equal [ "最近", "很久以前", "不記得" ], css_select("tbody td a").map(&:text)
    assert_select "tbody td > span:last-child", text: "日期不明"
    assert_select "tbody td > span:last-child", text: "—"
  end

  test "詢問單確認訂購後出現在已訂購，來源是系統記錄" do
    inquiry = create(:order_inquiry, headcount_at_creation: 18, total: 1620, subtotal: 1620)
    inquiry.confirm!

    get orders_path

    assert_select "tbody tr", count: 1
    assert_select "tbody td > span:last-child", text: "系統記錄"
    assert_select "tbody td > span:last-child", text: "NT$1,620"
  end

  test "已訂購沒有資料" do
    get orders_path

    assert_select "p", text: "還沒有訂購紀錄"
  end

  # --- 安全 ---

  test "店名中的 HTML 在紀錄表中會被跳脫" do
    merchant = create(:merchant, name: "<img src=x onerror=alert(1)>")
    create(:order_inquiry, merchant: merchant)
    create(:order_record, merchant: merchant)

    [ inquiries_path, orders_path ].each do |path|
      get path
      assert_select "tbody img", count: 0
    end
  end

  test "已設定帳密時，五個頁面都需要登入" do
    with_env(AUTH_ENV) do
      [ history_path, favorites_path, shortlist_path, inquiries_path, orders_path ].each do |path|
        get path
        assert_response :unauthorized, "#{path} 應該需要登入"
      end
    end
  end
end
