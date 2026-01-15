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

ActiveRecord::Schema[7.1].define(version: 2026_01_15_144253) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "shifts", force: :cascade do |t|
    t.date "date", null: false
    t.bigint "staff_id", null: false
    t.bigint "store_id", null: false
    t.time "start_time"
    t.time "end_time"
    t.integer "break_minutes", default: 60
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "staff_id"], name: "index_shifts_on_date_and_staff_id", unique: true
    t.index ["date", "store_id"], name: "index_shifts_on_date_and_store_id"
    t.index ["staff_id"], name: "index_shifts_on_staff_id"
    t.index ["store_id"], name: "index_shifts_on_store_id"
  end

  create_table "staffs", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.integer "role", default: 0, null: false
    t.bigint "base_store_id"
    t.string "nearest_station"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.index ["base_store_id"], name: "index_staffs_on_base_store_id"
    t.index ["code"], name: "index_staffs_on_code", unique: true
  end

  create_table "store_requirements", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.integer "day_type", default: 0, null: false
    t.integer "pharmacist_count", default: 0, null: false
    t.integer "clerk_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id", "day_type"], name: "index_store_requirements_on_store_id_and_day_type", unique: true
    t.index ["store_id"], name: "index_store_requirements_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "address"
    t.string "nearest_station"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_stores_on_code", unique: true
  end

  add_foreign_key "shifts", "staffs"
  add_foreign_key "shifts", "stores"
  add_foreign_key "staffs", "stores", column: "base_store_id"
  add_foreign_key "store_requirements", "stores"
end
