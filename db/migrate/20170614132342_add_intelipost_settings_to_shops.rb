class AddIntelipostSettingsToShops < ActiveRecord::Migration[5.0]
  def change
    add_column :shops, :intelipost_api_key, :string
    add_column :shops, :intelipost_id, :string
    add_column :shops, :intelipost_enabled, :boolean, default: false
  end
end
