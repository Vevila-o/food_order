require "test_helper"

class EmptyStateComponentTest < ViewComponent::TestCase
  test "顯示標題與說明" do
    render_inline(EmptyStateComponent.new(title: "還沒有店家")) { "先新增一間。" }

    assert_selector "p.font-bold", text: "還沒有店家"
    assert_text "先新增一間。"
  end

  test "action slot 放按鈕" do
    render_inline(EmptyStateComponent.new(title: "沒有結果")) do |empty|
      empty.with_action { "<a class='btn'>清除篩選</a>".html_safe }
    end

    assert_selector "a.btn", text: "清除篩選"
  end

  test "沒有說明與按鈕時只有標題" do
    render_inline(EmptyStateComponent.new(title: "沒有資料"))

    assert_selector "p", count: 1
    assert_no_selector "a"
  end
end
