class BreadcrumbComponentPreview < ViewComponent::Preview
  # 一層：首頁 > 目前頁面
  def single
    render BreadcrumbComponent.new(items: [ [ "收藏" ] ])
  end

  # 多層：中間的層可以點，最後一層是目前頁面
  def nested
    render BreadcrumbComponent.new(items: [ [ "【範例】阿嬤便當", "/merchants/1" ], [ "貼上菜單", "/merchants/1/menu_import/new" ], [ "預覽" ] ])
  end

  # 店名很長：手機會換行 / 截斷，不撐寬頁面
  def long_name
    render BreadcrumbComponent.new(items: [ [ "【範例】超級無敵長的店名巧克力珍珠奶茶專賣店分店", "/merchants/1" ], [ "編輯" ] ])
  end
end
