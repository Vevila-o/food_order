# 麵包屑：首頁 > … > 目前頁面。
#   items  首頁之後的每一層，`[[文字, 網址], …]`；最後一層是目前頁面（網址可省略，不做成連結）
# 首頁一律是第一層，不用傳。文字（例如店名）由 ERB 自動跳脫。
class BreadcrumbComponent < ViewComponent::Base
  Crumb = Data.define(:label, :href)

  def initialize(items:)
    @items = items
  end

  def crumbs
    [ Crumb.new("首頁", helpers.root_path), *@items.map { |label, href| Crumb.new(label, href) } ]
  end

  def current?(crumb) = crumb.equal?(crumbs.last)
end
