class PageHeaderComponentPreview < ViewComponent::Preview
  # 首頁：品牌小字 + 標題 + 右上角動作
  def home
    render(PageHeaderComponent.new(title: "找今晚的餐", eyebrow: "Ruby Jam 訂餐助手")) do |header|
      header.with_actions { render IconLinkComponent.new(icon: :plus, label: "新增店家", href: "/merchants/new") }
    end
  end

  # 內頁：返回連結 + 標題 + 副標
  def detail
    render(PageHeaderComponent.new(title: "【範例】阿嬤便當", subtitle: "大安區 · 0.2 公里")) do |header|
      header.with_back_link { render BackLinkComponent.new(label: "返回列表", href: "/") }
    end
  end

  # summary slot：標題下方放任意內容（例如標籤列）
  def with_summary
    render(PageHeaderComponent.new(title: "新增店家")) do |header|
      header.with_summary { tag.p("summary slot 的內容", class: "text-sm text-muted") }
    end
  end
end
