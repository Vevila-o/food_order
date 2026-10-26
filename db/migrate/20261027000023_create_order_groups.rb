class CreateOrderGroups < ActiveRecord::Migration[8.1]
  def change
    # 一場活動可同時向兩家店訂（一家餐食 + 一家飲料）：把兩張詢問單綁成一組，
    # 重開任一家都能帶出另一家，「已詢問」頁也能顯示成一組。
    create_table :order_groups do |t|
      t.references :event, null: false, foreign_key: true
      t.timestamps
    end

    # 詢問單離組（換搭檔、移除）時只是把欄位清掉，詢問單本身保留。
    # 注意：這裡刻意不用 add_reference ... foreign_key: true。SQLite 加外鍵會「重建整張表」
    # （order_inquiries），而 order_inquiry_items 有外鍵指向它，重建時子表資料會被清空
    # （實測：既有詢問單的品項全部消失）。有資料的表只用 add_column + add_index，關聯由 model 保證。
    add_column :order_inquiries, :order_group_id, :integer
    add_index :order_inquiries, :order_group_id
  end
end
