class AlertComponentPreview < ViewComponent::Preview
  # 提示訊息。type：notice 成功 / alert 警告 / info 一般
  # @param type select [notice, alert, info]
  def playground(type: "notice")
    render(AlertComponent.new(type: type)) { "已儲存店家資料" }
  end

  def all_types
    render_with_template
  end
end
