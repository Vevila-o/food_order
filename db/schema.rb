# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_27_000024) do
  create_table "app_settings", force: :cascade do |t|
    t.boolean "singleton", default: true, null: false
    t.string "delivery_place_name"
    t.string "delivery_address"
    t.string "delivery_floor"
    t.string "recipient_name"
    t.string "recipient_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tax_id"
    t.index ["singleton"], name: "index_app_settings_on_singleton", unique: true
    t.check_constraint "singleton", name: "app_settings_single_row"
  end

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.string "kktix_slug", null: false
    t.date "held_on", null: false
    t.time "delivery_from", default: "2000-01-01 19:00:00", null: false
    t.time "delivery_until", default: "2000-01-01 19:15:00", null: false
    t.time "starts_at", default: "2000-01-01 19:30:00", null: false
    t.string "github_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["held_on"], name: "index_events_on_held_on"
    t.index ["kktix_slug"], name: "index_events_on_kktix_slug", unique: true
  end

  create_table "maintenance_tasks_runs", force: :cascade do |t|
    t.string "task_name", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.float "time_running", default: 0.0, null: false
    t.bigint "tick_count"
    t.bigint "tick_total"
    t.string "job_id"
    t.string "cursor"
    t.string "status", default: "enqueued", null: false
    t.string "error_class"
    t.string "error_message"
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "arguments"
    t.integer "lock_version", default: 0, null: false
    t.text "metadata"
    t.boolean "cursor_is_json", default: false, null: false
    t.index ["task_name", "status", "created_at"], name: "index_maintenance_tasks_runs", order: { created_at: :desc }
  end

  create_table "menu_items", force: :cascade do |t|
    t.integer "merchant_id", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.integer "price", null: false
    t.date "menu_date"
    t.integer "source_id"
    t.string "unit"
    t.integer "servings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_menu_items_on_merchant_id"
    t.index ["source_id"], name: "index_menu_items_on_source_id"
    t.check_constraint "category IN ('food', 'drink')", name: "menu_items_category_values"
    t.check_constraint "price >= 0", name: "menu_items_price_non_negative"
    t.check_constraint "servings IS NULL OR servings > 0", name: "menu_items_servings_positive"
  end

  create_table "merchant_sources", force: :cascade do |t|
    t.integer "merchant_id", null: false
    t.string "platform", null: false
    t.string "url"
    t.datetime "posted_at"
    t.datetime "fetched_at"
    t.text "raw_excerpt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_merchant_sources_on_merchant_id"
    t.check_constraint "platform IN ('threads', 'instagram', 'google', 'web', 'manual')", name: "merchant_sources_platform_values"
  end

  create_table "merchants", force: :cascade do |t|
    t.string "name", null: false
    t.string "address"
    t.string "district"
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "lng", precision: 10, scale: 7
    t.string "phone"
    t.string "line_id"
    t.string "instagram"
    t.string "messenger_id"
    t.string "threads"
    t.boolean "offers_food", default: true, null: false
    t.boolean "offers_drink", default: false, null: false
    t.string "delivers_at_19", default: "unknown", null: false
    t.string "delivers_to_daan", default: "unknown", null: false
    t.integer "delivery_fee"
    t.integer "free_delivery_threshold"
    t.integer "price_per_person_min"
    t.integer "price_per_person_max"
    t.boolean "favorited", default: false, null: false
    t.boolean "shortlisted", default: false, null: false
    t.text "shortlist_note"
    t.integer "shortlist_position"
    t.datetime "last_verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_viewed_at"
    t.index ["favorited"], name: "index_merchants_on_favorited"
    t.index ["instagram"], name: "index_merchants_on_instagram"
    t.index ["last_viewed_at"], name: "index_merchants_on_last_viewed_at"
    t.index ["phone"], name: "index_merchants_on_phone"
    t.index ["shortlisted"], name: "index_merchants_on_shortlisted"
    t.check_constraint "(delivery_fee IS NULL OR delivery_fee >= 0) AND (free_delivery_threshold IS NULL OR free_delivery_threshold >= 0) AND (price_per_person_min IS NULL OR price_per_person_min >= 0) AND (price_per_person_max IS NULL OR price_per_person_max >= 0)", name: "merchants_money_non_negative"
    t.check_constraint "delivers_at_19 IN ('yes', 'no', 'unknown')", name: "merchants_delivers_at_19_values"
    t.check_constraint "delivers_to_daan IN ('yes', 'no', 'unknown')", name: "merchants_delivers_to_daan_values"
    t.check_constraint "offers_food OR offers_drink", name: "merchants_offers_something"
  end

  create_table "order_groups", force: :cascade do |t|
    t.integer "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_order_groups_on_event_id"
  end

  create_table "order_inquiries", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "merchant_id", null: false
    t.integer "headcount_at_creation", null: false
    t.integer "subtotal", null: false
    t.integer "delivery_fee"
    t.integer "total"
    t.text "message_text"
    t.string "status", default: "draft", null: false
    t.string "contacted_via"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order_group_id"
    t.index ["event_id", "merchant_id"], name: "index_order_inquiries_on_event_id_and_merchant_id", unique: true
    t.index ["event_id"], name: "index_order_inquiries_on_event_id"
    t.index ["merchant_id"], name: "index_order_inquiries_on_merchant_id"
    t.index ["order_group_id"], name: "index_order_inquiries_on_order_group_id"
    t.check_constraint "contacted_via IS NULL OR contacted_via IN ('line', 'instagram', 'messenger', 'phone')", name: "order_inquiries_contacted_via_values"
    t.check_constraint "status IN ('draft', 'sent', 'confirmed')", name: "order_inquiries_status_values"
    t.check_constraint "subtotal >= 0 AND (delivery_fee IS NULL OR delivery_fee >= 0) AND (total IS NULL OR total >= 0)", name: "order_inquiries_money_non_negative"
  end

  create_table "order_inquiry_items", force: :cascade do |t|
    t.integer "order_inquiry_id", null: false
    t.integer "menu_item_id"
    t.string "name", null: false
    t.string "unit"
    t.integer "quantity", null: false
    t.integer "unit_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_item_id"], name: "index_order_inquiry_items_on_menu_item_id"
    t.index ["order_inquiry_id"], name: "index_order_inquiry_items_on_order_inquiry_id"
    t.check_constraint "quantity > 0", name: "order_inquiry_items_quantity_positive"
    t.check_constraint "unit_price >= 0", name: "order_inquiry_items_unit_price_non_negative"
  end

  create_table "order_records", force: :cascade do |t|
    t.integer "merchant_id", null: false
    t.integer "event_id"
    t.integer "order_inquiry_id"
    t.date "ordered_on"
    t.integer "headcount"
    t.integer "total"
    t.string "source", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_order_records_on_event_id"
    t.index ["merchant_id"], name: "index_order_records_on_merchant_id"
    t.index ["order_inquiry_id"], name: "index_order_records_on_order_inquiry_id_unique", unique: true, where: "order_inquiry_id IS NOT NULL"
    t.check_constraint "(headcount IS NULL OR headcount >= 0) AND (total IS NULL OR total >= 0)", name: "order_records_numbers_non_negative"
    t.check_constraint "source IN ('inquiry', 'manual')", name: "order_records_source_values"
  end

  create_table "registration_snapshots", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "headcount", null: false
    t.string "source", null: false
    t.datetime "received_at", null: false
    t.string "kktix_order_id"
    t.string "kktix_event_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "kktix_order_id", "kktix_event_type"], name: "index_registration_snapshots_dedupe", unique: true, where: "kktix_order_id IS NOT NULL"
    t.index ["event_id", "received_at"], name: "index_registration_snapshots_on_event_id_and_received_at"
    t.index ["event_id"], name: "index_registration_snapshots_on_event_id"
    t.check_constraint "headcount >= 0", name: "registration_snapshots_headcount_non_negative"
    t.check_constraint "source IN ('webhook', 'manual')", name: "registration_snapshots_source_values"
  end

  add_foreign_key "menu_items", "merchant_sources", column: "source_id", on_delete: :nullify
  add_foreign_key "menu_items", "merchants"
  add_foreign_key "merchant_sources", "merchants"
  add_foreign_key "order_groups", "events"
  add_foreign_key "order_inquiries", "events"
  add_foreign_key "order_inquiries", "merchants", on_delete: :restrict
  add_foreign_key "order_inquiry_items", "menu_items", on_delete: :nullify
  add_foreign_key "order_inquiry_items", "order_inquiries", on_delete: :cascade
  add_foreign_key "order_records", "events", on_delete: :nullify
  add_foreign_key "order_records", "merchants", on_delete: :restrict
  add_foreign_key "order_records", "order_inquiries", on_delete: :cascade
  add_foreign_key "registration_snapshots", "events"
end
