require "test_helper"

class StepperComponentTest < ViewComponent::TestCase
  def render_stepper(**options)
    render_inline(StepperComponent.new(**{ name: "quantities[7]", value: 3, label: "雞腿便當" }.merge(options)))
  end

  test "數字輸入框帶欄位名稱、目前值、範圍與讀屏標籤" do
    render_stepper

    assert_selector "input[type=number][name='quantities[7]'][value='3'][min='0'][max='99'][aria-label='雞腿便當數量']"
  end

  test "減少與增加按鈕有讀屏標籤，並連到 stepper controller" do
    render_stepper

    assert_selector "button[type=button][aria-label='減少雞腿便當'][data-action='stepper#decrement']", text: "−"
    assert_selector "button[type=button][aria-label='增加雞腿便當'][data-action='stepper#increment']", text: "＋"
  end

  test "按鈕至少 44px（size-11）" do
    render_stepper(headcount: 18)

    assert_selector "button.size-11", count: 2
    assert_selector "button.tap-target", text: "＝ 人數"
  end

  test "有人數才顯示「＝ 人數」，並把人數交給 controller" do
    render_stepper(headcount: 18)

    assert_selector "[data-controller=stepper][data-stepper-headcount-value='18']"
    assert_selector "button[data-action='stepper#fill'][aria-label='雞腿便當數量設為人數 18']", text: "＝ 人數"
  end

  test "沒給人數：不顯示「＝ 人數」" do
    render_stepper

    assert_no_text "＝ 人數"
  end

  test "最大值可調整" do
    render_stepper(max: 10)

    assert_selector "input[max='10']"
    assert_selector "[data-stepper-max-value='10']"
  end
end
