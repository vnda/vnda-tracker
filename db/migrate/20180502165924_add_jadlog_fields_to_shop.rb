# frozen_string_literal: true

class AddJadlogFieldsToShop < ActiveRecord::Migration[5.1]
  def change
    add_column :shops, :jadlog_enabled, :boolean
    add_column :shops, :jadlog_registered_cnpj, :string
    add_column :shops, :jadlog_user_code, :string
    add_column :shops, :jadlog_password, :string
  end
end
