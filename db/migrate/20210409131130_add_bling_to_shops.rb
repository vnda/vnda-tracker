# frozen_string_literal: true

class AddBlingToShops < ActiveRecord::Migration[5.2]
  def change
    change_table :shops, bulk: true do |t|
      t.column :bling_enabled, :boolean, default: false
      t.column :bling_api_key, :string
      t.column :bling_status_in_transit, :string
      t.column :bling_status_delivered, :string
    end
  end
end
