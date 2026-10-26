class CreateMenuItems < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_items do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category, null: false # food / drink
      t.integer :price, null: false
      # 日期不明存 NULL：不進訂單詢問產生器
      t.date :menu_date
      # 來源被刪掉時菜單項目仍保留
      t.references :source, foreign_key: { to_table: :merchant_sources, on_delete: :nullify }
      # 箱、桶不是「一人一份」：單位（杯/份/箱/桶）與一單位可供幾人
      t.string :unit
      t.integer :servings

      t.timestamps
    end

    add_check_constraint :menu_items, "category IN ('food', 'drink')", name: "menu_items_category_values"
    add_check_constraint :menu_items, "price >= 0", name: "menu_items_price_non_negative"
    add_check_constraint :menu_items, "servings IS NULL OR servings > 0", name: "menu_items_servings_positive"
  end
end
