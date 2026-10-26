# 數量輸入（設計稿）：− [數字] ＋，可選「＝ 人數」快速按鈕。觸控範圍 44px（設計稿是 40px）。
# 實際值在 <input type=number>，所以沒有 JavaScript 也能直接輸入；按鈕由 stepper Stimulus controller 處理，
# 改值後會送出 input 事件，讓外層表單的 auto-submit 重新計算。
class StepperComponent < ViewComponent::Base
  # name：表單欄位名稱（quantities[12]）；label：品名，用在讀屏的標籤；headcount 有給才顯示「＝ 人數」
  def initialize(name:, value:, label:, headcount: nil, max: 99)
    @name = name
    @value = value
    @label = label
    @headcount = headcount
    @max = max
  end

  attr_reader :name, :value, :label, :headcount, :max

  def round_button_class
    "inline-flex size-11 shrink-0 cursor-pointer items-center justify-center rounded-full bg-base-200 text-xl leading-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-base-content"
  end
end
