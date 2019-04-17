# frozen_string_literal: true

class AddMandaeFiledsToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :mandae_enabled, :boolean
    add_column :shops, :mandae_token, :string
    add_column :shops, :mandae_pattern, :string
  end
end
