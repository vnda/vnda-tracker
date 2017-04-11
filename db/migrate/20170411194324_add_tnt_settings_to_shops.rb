class AddTntSettingsToShops < ActiveRecord::Migration[5.0]
  def change
    add_column :shops, :tnt_email, :string
    add_column :shops, :tnt_cnpj, :string
    add_column :shops, :tnt_enabled, :boolean
  end
end
