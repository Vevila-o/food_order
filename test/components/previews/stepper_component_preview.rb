class StepperComponentPreview < ViewComponent::Preview
  # 數量 − [數字] ＋，右邊「＝ 人數」把數量設成報名人數
  def default
    render StepperComponent.new(name: "quantities[1]", value: 0, label: "雞腿便當", headcount: 18)
  end

  # 沒有人數時不顯示「＝ 人數」
  def without_headcount
    render StepperComponent.new(name: "quantities[1]", value: 5, label: "紅茶")
  end

  # 已有數量
  def with_value
    render StepperComponent.new(name: "quantities[1]", value: 18, label: "雞腿便當", headcount: 18)
  end
end
