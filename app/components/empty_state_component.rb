# 空狀態：沒有資料時的說明與下一步（action slot 放按鈕）。
class EmptyStateComponent < ViewComponent::Base
  renders_one :action

  def initialize(title:)
    @title = title
  end
end
