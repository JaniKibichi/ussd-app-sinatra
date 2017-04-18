# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170406111730) do

  create_table "accounts", force: :cascade do |t|
    t.string   "phoneNumber"
    t.decimal  "balance"
    t.decimal  "loan"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["phoneNumber"], name: "index_accounts_on_phoneNumber"
  end

  create_table "checkouts", force: :cascade do |t|
    t.string   "phoneNumber"
    t.string   "status"
    t.decimal  "amount"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["phoneNumber"], name: "index_checkouts_on_phoneNumber"
  end

  create_table "microfinances", force: :cascade do |t|
    t.string   "phoneNumber"
    t.string   "name"
    t.string   "city"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["phoneNumber"], name: "index_microfinances_on_phoneNumber", unique: true
  end

  create_table "resources", force: :cascade do |t|
    t.string   "name",       default: "", null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["name"], name: "index_resources_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "phoneNumber"
    t.string   "sessionId"
    t.integer  "level"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["phoneNumber"], name: "index_sessions_on_phoneNumber"
  end

end
