# 側欄選單：全部店家 / 瀏覽歷史 / 收藏 / 下次訂購 / 已詢問 / 已訂購。
# 桌機固定在左側；手機放在左上角選單開出來的抽屜（layout 渲染兩份，只有一份看得到）。
class SidebarComponent < ViewComponent::Base
  # match：目前網址符合時標為「目前頁面」。全部店家涵蓋首頁與 /merchants 底下所有頁面（詳情、編輯…）
  Item = Data.define(:key, :label, :icon, :route, :match)

  ITEMS = [
    Item.new(key: :home, label: "全部店家", icon: :home, route: :root_path, match: %r{\A/(merchants(/.*)?)?\z}),
    Item.new(key: :history, label: "瀏覽歷史", icon: :history, route: :history_path, match: %r{\A/history\z}),
    Item.new(key: :favorites, label: "收藏", icon: :star, route: :favorites_path, match: %r{\A/favorites\z}),
    Item.new(key: :shortlist, label: "下次訂購", icon: :bookmark, route: :shortlist_path, match: %r{\A/shortlist\z}),
    Item.new(key: :inquiries, label: "已詢問", icon: :message, route: :inquiries_path, match: %r{\A/inquiries\z}),
    Item.new(key: :orders, label: "已訂購", icon: :check_circle, route: :orders_path, match: %r{\A/orders\z})
  ].freeze

  # counts：{ history: 3, favorites: 2, ... }，沒有的項目不顯示數量；數量 0 也不顯示（避免一排 0）
  def initialize(current_path:, counts: {})
    @current_path = current_path.to_s
    @counts = counts
  end

  def active?(item) = item.match.match?(@current_path)

  def path_for(item) = helpers.public_send(item.route)

  def count_for(item)
    count = @counts[item.key]
    count if count&.positive?
  end

  def link_class(item)
    base = "flex min-h-11 items-center gap-3 rounded-xl px-3 text-sm font-medium focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-base-content"
    active?(item) ? "#{base} bg-primary font-bold" : "#{base} hover:bg-base-100"
  end
end
