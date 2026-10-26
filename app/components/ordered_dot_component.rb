# 「曾訂購」圓點：橘色（accent）= 曾訂購、灰色 = 沒訂過。
# 旁邊一定附文字，不能只靠顏色（色覺與對比，WCAG）。
class OrderedDotComponent < ViewComponent::Base
  def initialize(ordered:)
    @ordered = ordered
  end

  def label = @ordered ? "曾訂購" : "沒訂過"

  def dot_class = @ordered ? "bg-accent" : "bg-gray-400"
end
