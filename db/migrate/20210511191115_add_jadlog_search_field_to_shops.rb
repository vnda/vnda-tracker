# frozen_string_literal: true

class AddJadlogSearchFieldToShops < ActiveRecord::Migration[5.2]
  def up
    add_column :shops, :jadlog_search_field, :string
    execute("UPDATE shops SET jadlog_search_field = 'shipmentId'")
    change_table :shops, bulk: true do |t|
      t.change :jadlog_search_field, :string, default: 'shipmentId', null: false
    end
  end

  def down
    remove_column :shops, :jadlog_search_field
  end
end
