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

ActiveRecord::Schema[7.1].define(version: 2025_06_15_104650) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "ban_status_types", ["banned", "not_banned"]

  create_table "integrity_logs", force: :cascade do |t|
    t.string "idfa", null: false
    t.string "ban_status", null: false
    t.inet "ip"
    t.boolean "rooted_device", default: false, null: false
    t.string "country", limit: 2
    t.boolean "proxy", default: false, null: false
    t.boolean "vpn", default: false, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_integrity_logs_on_created_at"
    t.index ["idfa"], name: "index_integrity_logs_on_idfa"
  end

  create_table "users", force: :cascade do |t|
    t.enum "ban_status", null: false, enum_type: "ban_status_types"
    t.string "idfa", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idfa"], name: "index_users_on_idfa", unique: true
  end

end
