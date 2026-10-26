# 頁首（設計稿）：白底 + 下方細線。每頁自己決定內容，不是全站導覽列。
#   eyebrow  標題上方的小字（首頁放品牌名）
#   subtitle 標題下方的小字（地址、距離等）
#   slots：back_link 返回連結 / actions 右上角按鈕 / summary 標題下方的內容（活動摘要卡、標籤列）
class PageHeaderComponent < ViewComponent::Base
  renders_one :back_link
  renders_one :actions
  renders_one :summary

  def initialize(title:, eyebrow: nil, subtitle: nil)
    @title = title
    @eyebrow = eyebrow
    @subtitle = subtitle
  end
end
