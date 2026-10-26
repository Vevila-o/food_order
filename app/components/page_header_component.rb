# 頁首（設計稿）：白底 + 下方細線。每頁自己決定內容，不是全站導覽列。
#   eyebrow  標題上方的小字（首頁放品牌名）
#   subtitle 標題下方的小字（地址、距離等）
#   nav_label 有給：標題列（品牌、標題、右上角按鈕）包成 <nav aria-label=...>（首頁用）
#   breadcrumb 首頁之後的每一層 [[文字, 網址], …]，最後一層是目前頁面（見 BreadcrumbComponent）；首頁不給
#   slots：actions 右上角按鈕 / summary 標題下方的內容（活動摘要卡、標籤列）
class PageHeaderComponent < ViewComponent::Base
  renders_one :actions
  renders_one :summary

  def initialize(title:, eyebrow: nil, subtitle: nil, nav_label: nil, breadcrumb: nil)
    @title = title
    @eyebrow = eyebrow
    @subtitle = subtitle
    @nav_label = nav_label
    @breadcrumb = breadcrumb
  end
end
