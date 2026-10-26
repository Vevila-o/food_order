class ContactButtonsComponentPreview < ViewComponent::Preview
  # 四種管道都有：LINE → Instagram → Messenger → 電話（第一顆是主要按鈕）
  def all_channels
    render ContactButtonsComponent.new(links: PreviewMerchants.build(line_id: "@rubyjam", instagram: "rubyjam.lunch", messenger_id: "rubyjam.page", phone: "02-2345-6789").contact_links)
  end

  # 只有電話
  def phone_only
    render ContactButtonsComponent.new(links: PreviewMerchants.build(phone: "02-2345-6789").contact_links)
  end

  # 還沒選餐點：按鈕停用
  def disabled
    render ContactButtonsComponent.new(links: PreviewMerchants.build(line_id: "@rubyjam", phone: "02-2345-6789").contact_links, disabled: true)
  end

  # 沒有任何聯絡方式：提示並附來源連結
  def no_contacts
    render ContactButtonsComponent.new(links: [], source_urls: [ "https://www.instagram.com/p/example/" ])
  end
end
