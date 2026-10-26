class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    # 金額一律整數「新台幣元」；「未知」存 NULL，不存 0。
    create_table :merchants do |t|
      t.string :name, null: false
      t.string :address
      t.string :district
      # 座標由 M5 自動搜尋取得，M2 可為 NULL（沒有座標就沒有距離）
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7

      # 線上聯絡管道：LINE 存含前綴的原值（@官方帳號 或 ~個人ID）
      t.string :phone
      t.string :line_id
      t.string :instagram
      t.string :messenger_id
      t.string :threads

      # 餐食 / 飲料至少賣一種；只賣飲料（桶裝、整箱）的店也可以出現
      t.boolean :offers_food, null: false, default: true
      t.boolean :offers_drink, null: false, default: false

      # yes / no / unknown：多數店家沒有結構化資料，預設「待確認」
      t.string :delivers_at_19, null: false, default: "unknown"
      t.string :delivers_to_daan, null: false, default: "unknown"
      t.integer :delivery_fee
      t.integer :free_delivery_threshold
      t.integer :price_per_person_min
      t.integer :price_per_person_max

      t.boolean :favorited, null: false, default: false
      t.boolean :shortlisted, null: false, default: false
      t.text :shortlist_note
      t.integer :shortlist_position

      t.datetime :last_verified_at

      t.timestamps
    end

    add_index :merchants, :favorited
    add_index :merchants, :shortlisted
    add_index :merchants, :phone
    add_index :merchants, :instagram

    add_check_constraint :merchants, "offers_food OR offers_drink", name: "merchants_offers_something"
    add_check_constraint :merchants, "delivers_at_19 IN ('yes', 'no', 'unknown')", name: "merchants_delivers_at_19_values"
    add_check_constraint :merchants, "delivers_to_daan IN ('yes', 'no', 'unknown')", name: "merchants_delivers_to_daan_values"
    add_check_constraint :merchants,
      "(delivery_fee IS NULL OR delivery_fee >= 0) AND " \
      "(free_delivery_threshold IS NULL OR free_delivery_threshold >= 0) AND " \
      "(price_per_person_min IS NULL OR price_per_person_min >= 0) AND " \
      "(price_per_person_max IS NULL OR price_per_person_max >= 0)",
      name: "merchants_money_non_negative"
  end
end
