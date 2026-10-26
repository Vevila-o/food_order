class FieldComponentPreview < ViewComponent::Preview
  # 表單欄位外框：標籤（取自 zh-TW.yml）、說明文字、錯誤訊息
  def default = render_form(Merchant.new, hint: "填店家的招牌名稱")

  def with_error
    merchant = Merchant.new
    merchant.validate
    render_form(merchant)
  end

  private

  def render_form(merchant, hint: nil)
    render_with_template(template: "field_component_preview/form", locals: { merchant: merchant, hint: hint })
  end
end
