class SidebarComponentPreview < ViewComponent::Preview
  COUNTS = { history: 8, favorites: 3, shortlist: 4, inquiries: 5, orders: 12 }.freeze

  # 目前在全部店家（首頁）；有數量的項目顯示數字
  def home
    render SidebarComponent.new(current_path: "/", counts: COUNTS)
  end

  # 店家詳情頁也算「全部店家」
  def merchant_detail
    render SidebarComponent.new(current_path: "/merchants/12", counts: COUNTS)
  end

  # @param path select [/history, /favorites, /shortlist, /inquiries, /orders]
  def other_pages(path: "/favorites")
    render SidebarComponent.new(current_path: path, counts: COUNTS)
  end

  # 剛開始使用：數量都是 0，不顯示數字
  def empty
    render SidebarComponent.new(current_path: "/", counts: { history: 0, favorites: 0, shortlist: 0, inquiries: 0, orders: 0 })
  end
end
