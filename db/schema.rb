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

ActiveRecord::Schema.define(version: 2021_05_11_191115) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "correios_histories", force: :cascade do |t|
    t.string "code", null: false
    t.text "response_body"
    t.integer "response_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shops", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notification_url"
    t.string "tnt_email"
    t.string "tnt_cnpj"
    t.boolean "tnt_enabled"
    t.string "intelipost_api_key"
    t.string "intelipost_id"
    t.boolean "intelipost_enabled", default: false
    t.boolean "forward_to_intelipost", default: false
    t.boolean "jadlog_enabled"
    t.string "jadlog_registered_cnpj"
    t.string "jadlog_user_code"
    t.string "jadlog_password"
    t.string "total_client_id"
    t.string "total_user"
    t.string "total_password"
    t.boolean "total_enabled", default: false
    t.boolean "mandae_enabled"
    t.string "mandae_token"
    t.string "mandae_pattern"
    t.string "slug"
    t.boolean "delivery_center_enabled"
    t.string "delivery_center_token"
    t.boolean "loggi_enabled"
    t.string "loggi_token"
    t.string "loggi_email"
    t.integer "loggi_shop_id"
    t.string "loggi_api_url"
    t.string "loggi_pattern"
    t.string "host"
    t.boolean "melhor_envio_enabled", default: false
    t.string "melhor_envio_environment"
    t.boolean "bling_enabled", default: false
    t.string "bling_api_key"
    t.string "bling_status_in_transit"
    t.string "bling_status_delivered"
    t.string "jadlog_search_field", default: "shipmentId", null: false
  end

  create_table "tracking_events", force: :cascade do |t|
    t.string "delivery_status"
    t.datetime "checkpoint_at"
    t.string "message"
    t.text "response_data"
    t.bigint "tracking_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tracking_id"], name: "index_tracking_events_on_tracking_id"
  end

  create_table "tracking_notifications", force: :cascade do |t|
    t.string "url"
    t.text "data"
    t.text "response"
    t.bigint "tracking_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tracking_id"], name: "index_tracking_notifications_on_tracking_id"
  end

  create_table "trackings", id: :serial, force: :cascade do |t|
    t.string "code"
    t.string "carrier"
    t.string "notification_url"
    t.string "delivery_status"
    t.string "tracker_url"
    t.integer "shop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_checkpoint_at"
    t.string "package"
    t.text "last_response"
    t.index ["shop_id"], name: "index_trackings_on_shop_id"
  end

end
