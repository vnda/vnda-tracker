# frozen_string_literal: true

class AddDeliveryCenterToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :delivery_center_enabled, :boolean
    add_column :shops, :delivery_center_token, :string
  end
end
