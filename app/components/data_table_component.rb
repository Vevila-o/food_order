# 紀錄表（已詢問、已訂購）：桌機是一般表格，手機每一筆變成一張卡片（欄位名稱放在每格左邊）。
#   rows 是二維陣列，格子可以是字串（會跳脫）或 html_safe 的內容（連結、標籤）。
class DataTableComponent < ViewComponent::Base
  def initialize(headers:, rows:, caption:)
    @headers = headers
    @rows = rows
    @caption = caption
  end

  attr_reader :headers, :rows, :caption
end
