# 表單欄位外框：標籤 + 輸入元件（content）+ 說明文字 + 錯誤訊息。
#   <%= render FieldComponent.new(form: f, attribute: :name) do %>
#     <%= f.text_field :name, class: "input w-full" %>
#   <% end %>
# 標籤預設取 zh-TW.yml 的欄位名稱。
class FieldComponent < ViewComponent::Base
  def initialize(form:, attribute:, label: nil, hint: nil, required: false)
    @form = form
    @attribute = attribute
    @label = label
    @hint = hint
    @required = required
  end

  def errors = @form.object.errors[@attribute]

  def label_text = @label || @form.object.class.human_attribute_name(@attribute)

  # 標籤內容：欄位名稱 + 必填記號（記號只是裝飾，用 aria-hidden 隱藏）
  def label_content
    return label_text unless @required

    safe_join([ label_text, tag.span("＊", class: "ml-1", "aria-hidden": "true") ])
  end
end
