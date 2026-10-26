# 側欄「下次訂購」：加入下次候選的店家，依加入順序（Merchant.shortlisted）排列，不像收藏頁以收藏優先排序。
# 排序調整與備註留到 M2-c（候選名單頁）。
class ShortlistedMerchantsController < ApplicationController
  def index
    @merchants = Merchant.shortlisted.includes(:menu_items, :order_records).to_a
  end
end
