# 側欄「瀏覽歷史」：最近打開過詳情頁的店家，最近的在前，最多 20 間（見 Merchant.recently_viewed）
class BrowsingHistoriesController < ApplicationController
  def index
    @merchants = Merchant.recently_viewed.includes(:menu_items, :order_records)
  end
end
