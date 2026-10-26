# 聯絡按鈕：只顯示該店「有資料」的管道，順序 LINE → Instagram → Messenger → 電話（Merchant#contact_links）。
# 每顆按鈕的點擊由 inquiry Stimulus controller 處理：先複製訊息，成功後標為已詢問並開啟對方的帳號。
# 沒有任何管道時顯示「尚無聯絡方式，請到來源網址查看」與來源連結。
class ContactButtonsComponent < ViewComponent::Base
  # links：[[:line, "https://..."], ...]；source_urls：來源網址（沒有聯絡方式時顯示）；disabled：還沒選餐點、數量錯誤或已確認訂購
  def initialize(links:, source_urls: [], disabled: false)
    @links = links
    @source_urls = source_urls
    @disabled = disabled
  end

  attr_reader :links, :source_urls

  def disabled? = @disabled

  def button_class(index)
    base = "btn min-h-11 flex-1 sm:flex-none"
    index.zero? ? "#{base} btn-primary" : "#{base} btn-outline"
  end
end
