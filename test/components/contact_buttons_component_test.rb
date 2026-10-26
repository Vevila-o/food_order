require "test_helper"

class ContactButtonsComponentTest < ViewComponent::TestCase
  def links(**attrs) = build(:merchant, **attrs).contact_links

  test "只顯示有資料的管道，順序 LINE → Instagram → Messenger → 電話" do
    render_inline(ContactButtonsComponent.new(links: links(line_id: "@abc", instagram: "abc.ig", messenger_id: "abc.page", phone: "02-2345-6789")))

    assert_equal %w[LINE Instagram Messenger 電話], page.all("button").map { |button| button.text.strip }
    assert_equal %w[line instagram messenger phone], page.all("button").map { |button| button["data-inquiry-channel-param"] }
  end

  test "每顆按鈕帶管道與連結，由 inquiry controller 處理（不是一般連結）" do
    render_inline(ContactButtonsComponent.new(links: links(line_id: "@abc", phone: "02-2345-6789")))

    assert_selector "button[type=button][data-action='inquiry#contact'][data-inquiry-channel-param=line][data-inquiry-href-param='https://line.me/R/ti/p/@abc']"
    assert_selector "button[data-inquiry-channel-param=phone][data-inquiry-href-param='tel:0223456789']"
    assert_no_selector "a"
  end

  test "沒有的管道不顯示" do
    render_inline(ContactButtonsComponent.new(links: links(phone: "02-2345-6789")))

    assert_selector "button", count: 1
    assert_no_text "LINE"
  end

  test "第一顆是主要按鈕，其餘是外框按鈕" do
    render_inline(ContactButtonsComponent.new(links: links(line_id: "@abc", phone: "02-2345-6789")))

    assert_selector "button.btn-primary", text: "LINE"
    assert_selector "button.btn-outline", text: "電話"
  end

  test "停用時按鈕 disabled 並說明原因" do
    render_inline(ContactButtonsComponent.new(links: links(line_id: "@abc"), disabled: true))

    assert_selector "button[disabled]", text: "LINE"
    assert_text "選好餐點後才能複製訊息"
  end

  test "沒有任何聯絡方式：提示，並附來源連結（開新分頁、noopener）" do
    render_inline(ContactButtonsComponent.new(links: [], source_urls: [ "https://example.com/post" ]))

    assert_text "尚無聯絡方式，請到來源網址查看"
    assert_no_selector "button"
    assert_selector "a[href='https://example.com/post'][target=_blank][rel~=noopener]"
  end

  test "有狀態訊息區（複製結果會顯示在這裡）" do
    render_inline(ContactButtonsComponent.new(links: links(line_id: "@abc")))

    assert_selector "p[role=status][aria-live=polite][data-inquiry-target=status]"
  end
end
