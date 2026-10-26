# 提示訊息（flash）。type：notice 成功 / alert 警告 / info 一般
class AlertComponent < ViewComponent::Base
  STYLES = { notice: "alert-success", alert: "alert-warning", info: "alert-info" }.freeze

  def initialize(type: :info)
    @type = type.to_sym
  end

  def css_class = STYLES.fetch(@type, STYLES[:info])
end
