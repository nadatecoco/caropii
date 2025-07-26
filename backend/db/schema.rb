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

ActiveRecord::Schema[8.0].define(version: 2025_07_26_041849) do
  create_table "food_entries", force: :cascade do |t|
    t.string "food_name"
    t.decimal "protein"
    t.decimal "fat"
    t.decimal "carbs"
    t.decimal "calories"
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "foods", force: :cascade do |t|
    t.string "name"
    t.decimal "protein"
    t.decimal "fat"
    t.decimal "carbs"
    t.decimal "calories"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sleep_records", force: :cascade do |t|
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.integer "sleep_value", null: false
    t.string "data_source"
    t.decimal "duration_hours", precision: 4, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["start_time", "end_time"], name: "index_sleep_records_on_start_time_and_end_time"
    t.index ["start_time"], name: "index_sleep_records_on_start_time"
  end
end
