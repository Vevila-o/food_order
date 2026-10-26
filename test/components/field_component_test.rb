require "test_helper"

class FieldComponentTest < ViewComponent::TestCase
  def builder_for(merchant)
    ActionView::Helpers::FormBuilder.new(:merchant, merchant, vc_test_controller.view_context, {})
  end

  def render_field(merchant, **options)
    form = builder_for(merchant)
    render_inline(FieldComponent.new(form: form, attribute: :name, **options)) { form.text_field(:name) }
  end

  test "標籤預設取 zh-TW.yml 的欄位名稱" do
    render_field(Merchant.new)

    assert_selector "label[for='merchant_name']", text: "店名"
    assert_selector "input#merchant_name"
  end

  test "自訂標籤、必填記號與說明文字" do
    render_field(Merchant.new, label: "店家名稱", required: true, hint: "填招牌名稱")

    assert_selector "label", text: "店家名稱"
    assert_selector "label [aria-hidden=true]", text: "＊"
    assert_selector "p", text: "填招牌名稱"
  end

  test "顯示該欄位的錯誤訊息（role=alert）" do
    merchant = Merchant.new
    merchant.validate

    render_field(merchant)

    assert_selector "p[role=alert]", text: "不能為空白"
  end

  test "沒有錯誤時不顯示錯誤區" do
    render_field(Merchant.new(name: "阿嬤便當").tap(&:validate))

    assert_no_selector "p[role=alert]"
  end
end
