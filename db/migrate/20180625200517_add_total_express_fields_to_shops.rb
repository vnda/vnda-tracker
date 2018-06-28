# frozen_string_literal: true

class AddTotalExpressFieldsToShops < ActiveRecord::Migration[5.1]
  def change
    add_column :shops, :total_client_id, :string
    add_column :shops, :total_user, :string
    add_column :shops, :total_password, :string
    add_column :shops, :total_enabled, :boolean, default: false
  end
end
