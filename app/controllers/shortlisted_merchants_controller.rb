# 側欄「下次訂購」（候選名單頁）：加入下次候選的店家，依自己排的順序（Merchant.shortlisted）排列，
# 不像收藏頁以收藏優先排序。每間店可以往前 / 往後移一位、寫備註（Merchants::ShortlistsController#move / #update）。
class ShortlistedMerchantsController < ApplicationController
  def index
    @merchants = Merchant.shortlisted.includes(:menu_items, :order_records).to_a
  end
end
