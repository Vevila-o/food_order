# 側欄「收藏」：已收藏的店家。重用首頁的篩選（只看收藏），排序與卡片都和首頁一致。
class FavoriteMerchantsController < ApplicationController
  def index
    @merchants = MerchantFilter.new({ favorited: "1" }).merchants
  end
end
