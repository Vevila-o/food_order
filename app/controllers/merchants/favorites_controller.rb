module Merchants
  class FavoritesController < TogglesController
    def create
      @merchant.favorite!(true)
      respond_with_button(:favorite)
    end

    def destroy
      @merchant.favorite!(false)
      respond_with_button(:favorite)
    end
  end
end
