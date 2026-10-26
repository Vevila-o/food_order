class MerchantsController < ApplicationController
  before_action :set_merchant, only: %i[show edit update destroy verify_menu]

  # 卡片列表 + 篩選。條件放在網址（filter[...]），可分享、開新分頁也保留。
  def index
    @event = Event.current
    @filter = MerchantFilter.new(filter_params, budget: @event&.total_budget)
    @merchants = @filter.merchants
    @total_count = Merchant.count
  end

  def show
  end

  def new
    @merchant = Merchant.new
  end

  def edit
  end

  def create
    @merchant = Merchant.new(merchant_params)

    if @merchant.save
      redirect_to @merchant, **saved_flash("已新增店家")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @merchant.update(merchant_params)
      redirect_to @merchant, **saved_flash("已更新店家")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @merchant.destroy
      redirect_to merchants_path, notice: "已刪除「#{@merchant.name}」", status: :see_other
    else
      # 有詢問單或訂購紀錄的店家不可刪除，否則歷史會斷
      redirect_to @merchant, alert: "「#{@merchant.name}」已有詢問單或訂購紀錄，無法刪除", status: :see_other
    end
  end

  def verify_menu
    @merchant.verify_menu!
    redirect_to @merchant, notice: "已確認菜單仍有效，菜單日期更新為今天", status: :see_other
  end

  private

  # filter 不是 Hash（例如 ?filter=oops）時 permit 會把它丟掉，得到空條件，不會 500
  def filter_params
    params.permit(filter: [ :sort, *MerchantFilter::FLAGS, { kinds: [] } ])[:filter].to_h
  end

  def set_merchant
    @merchant = Merchant.includes(:menu_items, :sources, :order_records).find(params.expect(:id))
  end

  def merchant_params
    params.expect(
      merchant: [
        :name, :address, :district, :phone, :line_id, :instagram, :messenger_id, :threads,
        :offers_food, :offers_drink, :delivers_at_19, :delivers_to_daan,
        :delivery_fee, :free_delivery_threshold, :price_per_person_min, :price_per_person_max,
        { menu_items_attributes: [ [ :id, :name, :category, :price, :menu_date, :unit, :servings, :_destroy ] ],
          sources_attributes: [ [ :id, :platform, :url, :_destroy ] ] }
      ]
    )
  end

  # 存檔後若電話 / IG 與其他店家相同，提醒可能重複（不擋存檔）
  def saved_flash(message)
    duplicates = @merchant.possible_duplicates
    if duplicates.any?
      { alert: "#{message}。電話或 Instagram 與「#{duplicates.map(&:name).join('、')}」相同，可能是重複店家" }
    else
      { notice: message }
    end
  end
end
