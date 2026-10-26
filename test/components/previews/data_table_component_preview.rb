class DataTableComponentPreview < ViewComponent::Preview
  # 桌機是表格；縮到手機寬度每筆變成卡片
  def inquiries
    rows = [
      [ "2026 年 10 月", "【範例】阿嬤便當", render_pill(:primary, "已確認訂購"), "LINE", "18", "NT$1,620" ],
      [ "2026 年 9 月", "【範例】綠光輕食", render_pill(:soft, "已按聯絡按鈕"), "Instagram", "16", render_pill(:secondary, "待確認") ],
      [ "2026 年 8 月", "【範例】公館義大利麵", render_pill(:base, "草稿"), "—", "15", "NT$1,500" ]
    ]
    render DataTableComponent.new(headers: %w[活動 店家 狀態 管道 人數 金額], rows: rows, caption: "已詢問的紀錄")
  end

  # 格子內容會被跳脫（不會當成 HTML）
  def escaped_cells
    render DataTableComponent.new(headers: %w[店家 備註], rows: [ [ "<b>粗體店名</b>", "<script>alert(1)</script>" ] ], caption: "跳脫測試")
  end

  private

  def render_pill(tone, text) = render(PillComponent.new(tone: tone)) { text }
end
