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

    # 儲存候選備註
    def update
      if @merchant.update_shortlist_note!(params.permit(:shortlist_note)[:shortlist_note])
        redirect_to shortlist_path, notice: "已儲存「#{@merchant.name}」的備註", status: :see_other
      else
        redirect_to shortlist_path, alert: "備註最多 #{Merchant::SHORTLIST_NOTE_LIMIT} 字", status: :see_other
      end
    end

    # 往前 / 往後一位（頁面用 Turbo morph 重新整理，捲動位置保留）
    def move
      @merchant.move_in_shortlist!(params.permit(:direction)[:direction])
      redirect_to shortlist_path, status: :see_other
    end
  end
end
