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

ActiveRecord::Schema[8.1].define(version: 2026_10_27_000021) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "app_settings", force: :cascade do |t|
    t.boolean "singleton", default: true, null: false
    t.string "delivery_place_name"
    t.string "delivery_address"
    t.string "delivery_floor"
    t.string "recipient_name"
    t.string "recipient_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.bigint "tick_count", default: 0, null: false
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
    t.bigint "merchant_id", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.integer "price", null: false
    t.date "menu_date"
    t.bigint "source_id"
    t.string "unit"
    t.integer "servings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_menu_items_on_merchant_id"
    t.index ["source_id"], name: "index_menu_items_on_source_id"
    t.check_constraint "category::text = ANY (ARRAY['food'::character varying, 'drink'::character varying]::text[])", name: "menu_items_category_values"
    t.check_constraint "price >= 0", name: "menu_items_price_non_negative"
    t.check_constraint "servings IS NULL OR servings > 0", name: "menu_items_servings_positive"
  end

  create_table "merchant_sources", force: :cascade do |t|
    t.bigint "merchant_id", null: false
    t.string "platform", null: false
    t.string "url"
    t.datetime "posted_at"
    t.datetime "fetched_at"
    t.text "raw_excerpt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_merchant_sources_on_merchant_id"
    t.check_constraint "platform::text = ANY (ARRAY['threads'::character varying, 'instagram'::character varying, 'google'::character varying, 'web'::character varying, 'manual'::character varying]::text[])", name: "merchant_sources_platform_values"
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
    t.index ["favorited"], name: "index_merchants_on_favorited"
    t.index ["instagram"], name: "index_merchants_on_instagram"
    t.index ["phone"], name: "index_merchants_on_phone"
    t.index ["shortlisted"], name: "index_merchants_on_shortlisted"
    t.check_constraint "(delivery_fee IS NULL OR delivery_fee >= 0) AND (free_delivery_threshold IS NULL OR free_delivery_threshold >= 0) AND (price_per_person_min IS NULL OR price_per_person_min >= 0) AND (price_per_person_max IS NULL OR price_per_person_max >= 0)", name: "merchants_money_non_negative"
    t.check_constraint "delivers_at_19::text = ANY (ARRAY['yes'::character varying, 'no'::character varying, 'unknown'::character varying]::text[])", name: "merchants_delivers_at_19_values"
    t.check_constraint "delivers_to_daan::text = ANY (ARRAY['yes'::character varying, 'no'::character varying, 'unknown'::character varying]::text[])", name: "merchants_delivers_to_daan_values"
    t.check_constraint "offers_food OR offers_drink", name: "merchants_offers_something"
  end

  create_table "order_inquiries", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "merchant_id", null: false
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
    t.index ["event_id", "merchant_id"], name: "index_order_inquiries_on_event_id_and_merchant_id", unique: true
    t.index ["event_id"], name: "index_order_inquiries_on_event_id"
    t.index ["merchant_id"], name: "index_order_inquiries_on_merchant_id"
    t.check_constraint "contacted_via IS NULL OR (contacted_via::text = ANY (ARRAY['line'::character varying, 'instagram'::character varying, 'messenger'::character varying, 'phone'::character varying]::text[]))", name: "order_inquiries_contacted_via_values"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'sent'::character varying, 'confirmed'::character varying]::text[])", name: "order_inquiries_status_values"
    t.check_constraint "subtotal >= 0 AND (delivery_fee IS NULL OR delivery_fee >= 0) AND (total IS NULL OR total >= 0)", name: "order_inquiries_money_non_negative"
  end

  create_table "order_inquiry_items", force: :cascade do |t|
    t.bigint "order_inquiry_id", null: false
    t.bigint "menu_item_id"
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
    t.bigint "merchant_id", null: false
    t.bigint "event_id"
    t.bigint "order_inquiry_id"
    t.date "ordered_on"
    t.integer "headcount"
    t.integer "total"
    t.string "source", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_order_records_on_event_id"
    t.index ["merchant_id"], name: "index_order_records_on_merchant_id"
    t.index ["order_inquiry_id"], name: "index_order_records_on_order_inquiry_id_unique", unique: true, where: "(order_inquiry_id IS NOT NULL)"
    t.check_constraint "(headcount IS NULL OR headcount >= 0) AND (total IS NULL OR total >= 0)", name: "order_records_numbers_non_negative"
    t.check_constraint "source::text = ANY (ARRAY['inquiry'::character varying, 'manual'::character varying]::text[])", name: "order_records_source_values"
  end

  create_table "registration_snapshots", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.integer "headcount", null: false
    t.string "source", null: false
    t.datetime "received_at", null: false
    t.string "kktix_order_id"
    t.string "kktix_event_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "kktix_order_id", "kktix_event_type"], name: "index_registration_snapshots_dedupe", unique: true, where: "(kktix_order_id IS NOT NULL)"
    t.index ["event_id", "received_at"], name: "index_registration_snapshots_on_event_id_and_received_at"
    t.index ["event_id"], name: "index_registration_snapshots_on_event_id"
    t.check_constraint "headcount >= 0", name: "registration_snapshots_headcount_non_negative"
    t.check_constraint "source::text = ANY (ARRAY['webhook'::character varying, 'manual'::character varying]::text[])", name: "registration_snapshots_source_values"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  add_foreign_key "menu_items", "merchant_sources", column: "source_id", on_delete: :nullify
  add_foreign_key "menu_items", "merchants"
  add_foreign_key "merchant_sources", "merchants"
  add_foreign_key "order_inquiries", "events"
  add_foreign_key "order_inquiries", "merchants", on_delete: :restrict
  add_foreign_key "order_inquiry_items", "menu_items", on_delete: :nullify
  add_foreign_key "order_inquiry_items", "order_inquiries", on_delete: :cascade
  add_foreign_key "order_records", "events", on_delete: :nullify
  add_foreign_key "order_records", "merchants", on_delete: :restrict
  add_foreign_key "order_records", "order_inquiries", on_delete: :cascade
  add_foreign_key "registration_snapshots", "events"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
