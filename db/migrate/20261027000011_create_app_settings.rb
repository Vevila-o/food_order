class CreateAppSettings < ActiveRecord::Migration[8.1]
  def change
    # 單列設定表：收餐資訊全站共用、每月不變
    create_table :app_settings do |t|
      t.boolean :singleton, null: false, default: true
      t.string :delivery_place_name
      t.string :delivery_address
      t.string :delivery_floor
      t.string :recipient_name
      t.string :recipient_phone

      t.timestamps
    end

    # 固定欄位 + 唯一索引 + CHECK：資料庫層保證只會有一列
    add_index :app_settings, :singleton, unique: true
    add_check_constraint :app_settings, "singleton", name: "app_settings_single_row"
  end
end
