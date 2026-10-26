# 膠囊標籤（設計稿的 pill）：店家類型、估價、菜單日期、「待確認」等共用。
# tone：base 一般 / accent 強調（餐＋飲）/ soft 淺藍綠 / secondary 待確認、僅飲料 / primary 完成（已確認）/ warning 警示
class PillComponent < ViewComponent::Base
  TONES = {
    base: "bg-base-200 text-base-content",
    accent: "bg-accent text-accent-content font-bold",
    soft: "bg-soft text-base-content",
    secondary: "bg-secondary text-secondary-content",
    primary: "bg-primary text-primary-content font-bold",
    warning: "bg-warning text-warning-content"
  }.freeze

  def initialize(tone: :base)
    @tone = tone.to_sym
  end

  def css_class = "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{TONES.fetch(@tone)}"
end
