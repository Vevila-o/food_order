class CreateOrderInquiryItems < ActiveRecord::Migration[8.1]
  def change
    # 詢問單內容是「快照」：菜單日後改價或刪除，不影響歷史
    create_table :order_inquiry_items do |t|
      t.references :order_inquiry, null: false, foreign_key: { on_delete: :cascade }
      t.references :menu_item, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.string :unit
      t.integer :quantity, null: false
      t.integer :unit_price, null: false

      t.timestamps
    end

    add_check_constraint :order_inquiry_items, "quantity > 0", name: "order_inquiry_items_quantity_positive"
    add_check_constraint :order_inquiry_items, "unit_price >= 0", name: "order_inquiry_items_unit_price_non_negative"
  end
end
