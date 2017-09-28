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

ActiveRecord::Schema.define(version: 20170928154456) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "shops", force: :cascade do |t|
    t.string   "name"
    t.string   "token"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "notification_url"
    t.string   "tnt_email"
    t.string   "tnt_cnpj"
    t.boolean  "tnt_enabled"
    t.string   "intelipost_api_key"
    t.string   "intelipost_id"
    t.boolean  "intelipost_enabled",    default: false
    t.boolean  "forward_to_intelipost", default: false
  end

  create_table "trackings", force: :cascade do |t|
    t.string   "code"
    t.string   "carrier"
    t.string   "notification_url"
    t.string   "delivery_status"
    t.string   "tracker_url"
    t.integer  "shop_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.datetime "last_checkpoint_at"
    t.string   "package"
    t.index ["shop_id"], name: "index_trackings_on_shop_id", using: :btree
  end

end
