# frozen_string_literal: true

class AddMelhorEnvioToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :melhor_envio_enabled, :boolean, default: false
    add_column :shops, :melhor_envio_environment, :string
  end
end
