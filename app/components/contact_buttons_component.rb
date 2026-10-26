# 聯絡按鈕：只顯示該店「有資料」的管道，順序 LINE → Instagram → Messenger → 電話（Merchant#contact_links）。
# 每顆按鈕的點擊由 inquiry Stimulus controller 處理：先複製訊息，成功後標為已詢問並開啟對方的帳號。
# 沒有任何管道時顯示「尚無聯絡方式，請到來源網址查看」與來源連結。
class ContactButtonsComponent < ViewComponent::Base
  # links：[[:line, "https://..."], ...]；source_urls：來源網址（沒有聯絡方式時顯示）；disabled：還沒選餐點、數量錯誤或已確認訂購
  # message_id：按鈕要複製的訊息元素 id（MessagePreviewComponent 的 dom_id）；merchant_id：被標為已詢問的店家；title：兩家時帶店名
  def initialize(links:, source_urls: [], disabled: false, message_id: "inquiry-message", merchant_id: nil, title: "聯絡店家")
    @links = links
    @source_urls = source_urls
    @disabled = disabled
    @message_id = message_id
    @merchant_id = merchant_id
    @title = title
  end

  attr_reader :links, :source_urls, :message_id, :merchant_id, :title

  def disabled? = @disabled

  def button_class(index)
    base = "btn min-h-11 flex-1 sm:flex-none"
    index.zero? ? "#{base} btn-primary" : "#{base} btn-outline"
  end
end
