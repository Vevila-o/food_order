require "test_helper"

class DataTableComponentTest < ViewComponent::TestCase
  def render_table(rows: [ [ "2026 年 10 月", "阿嬤便當", "NT$1,620" ] ], headers: %w[活動 店家 金額])
    render_inline(DataTableComponent.new(headers: headers, rows: rows, caption: "已詢問的紀錄"))
  end

  test "有隱藏的 caption 供讀屏使用，表頭是 th scope=col" do
    render_table

    assert_selector "caption.sr-only", text: "已詢問的紀錄"
    assert_selector "thead th[scope=col]", count: 3
    assert_selector "thead th", text: "店家"
  end

  test "每筆資料一列，每格對應表頭" do
    render_table(rows: [ %w[A1 B1 C1], %w[A2 B2 C2] ])

    assert_selector "tbody tr", count: 2
    assert_selector "tbody tr:first-child td", count: 3
    assert_text "B2"
  end

  test "手機：每格左邊顯示欄位名稱（桌機隱藏），整列變成卡片" do
    render_table

    assert_selector "td span.md\\:hidden", text: "活動"
    assert_selector "tr.rounded-2xl.bg-base-100"
    assert_selector "thead.hidden"
  end

  test "格子可放 html_safe 的內容（連結、標籤）" do
    render_table(rows: [ [ "2026 年 10 月", "<a href='/merchants/1'>阿嬤便當</a>".html_safe, "NT$1,620" ] ])

    assert_selector "td a[href='/merchants/1']", text: "阿嬤便當"
  end

  test "一般字串會被跳脫，不會當成 HTML 執行" do
    render_table(rows: [ [ "<script>alert(1)</script>", "<b>粗體</b>", "x" ] ])

    assert_no_selector "script"
    assert_no_selector "b"
    assert_text "<b>粗體</b>"
  end

  test "沒有資料時只有表頭" do
    render_table(rows: [])

    assert_selector "tbody tr", count: 0
    assert_selector "thead th", count: 3
  end
end
