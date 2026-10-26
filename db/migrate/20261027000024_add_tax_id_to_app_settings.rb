class AddTaxIdToAppSettings < ActiveRecord::Migration[8.1]
  def change
    # 統一編號（8 碼）：開發票用，存成字串（開頭可能是 0）
    add_column :app_settings, :tax_id, :string
  end
end
