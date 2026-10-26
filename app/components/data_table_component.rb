# 紀錄表（已詢問、已訂購）：桌機是一般表格，手機每一筆變成一張卡片（欄位名稱放在每格左邊）。
#   rows 是二維陣列，格子可以是字串（會跳脫）或 html_safe 的內容（連結、標籤）。
#   wrap_columns：桌機允許換行（並保留最小寬度）的欄位索引，例如店名、搭配；其他欄位一律不換行，
#   否則欄位多的表格會把短欄位擠成一個字一行。給 nil（預設）就是所有欄位都可換行。
#   表格比容器寬時（欄位很多的小桌機）桌機版可橫向捲動，不會把頁面撐寬或切掉最右邊的欄位。
class DataTableComponent < ViewComponent::Base
  def initialize(headers:, rows:, caption:, wrap_columns: nil)
    @headers = headers
    @rows = rows
    @caption = caption
    @wrap_columns = wrap_columns
  end

  attr_reader :headers, :rows, :caption

  # 桌機的格子寬度規則
  def cell_class(index)
    classes = +"flex items-center justify-between gap-3 py-1 md:table-cell md:px-3 md:py-3"
    classes << " font-medium" if index.zero?
    if @wrap_columns.nil? || @wrap_columns.include?(index)
      classes << " md:min-w-36" unless @wrap_columns.nil?
    else
      classes << " md:whitespace-nowrap"
    end
    classes
  end
end
