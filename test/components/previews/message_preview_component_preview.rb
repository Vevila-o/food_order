class MessagePreviewComponentPreview < ViewComponent::Preview
  TEXT = <<~TEXT.chomp.freeze
    您好！想詢問 10/27（週二）19:00–19:15 之間，是否能外送以下餐點到 PicCollage 公司總部（台北市大安區光復南路 102 號 3 樓）：
    - 雞腿便當 × 18 份
    依菜單價格估計小計約 NT$1,620。
    想請問是否需要外送費？
    謝謝！
  TEXT

  def default
    render MessagePreviewComponent.new(text: TEXT)
  end

  # 活動日期已過：訊息旁多一行提醒
  def date_passed
    render MessagePreviewComponent.new(text: TEXT, notice: "活動日期 10/27 已過，請確認日期再送出")
  end
end
