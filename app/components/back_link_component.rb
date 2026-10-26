# 頁首的「返回」連結（箭頭 + 文字，可點擊範圍 ≥ 44px）。
class BackLinkComponent < ViewComponent::Base
  def initialize(label:, href:)
    @label = label
    @href = href
  end
end
