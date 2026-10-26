module Merchants
  class ShortlistsController < TogglesController
    def create
      @merchant.add_to_shortlist!
      respond_with_button(:shortlist)
    end

    def destroy
      @merchant.remove_from_shortlist!
      respond_with_button(:shortlist)
    end
  end
end
