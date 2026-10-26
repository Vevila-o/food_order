class AddLastViewedAtToMerchants < ActiveRecord::Migration[8.1]
  def change
    # 瀏覽歷史：打開店家頁時更新。一間店只記最後一次（單人使用，不需要完整瀏覽軌跡）
    add_column :merchants, :last_viewed_at, :datetime
    add_index :merchants, :last_viewed_at
  end
end
