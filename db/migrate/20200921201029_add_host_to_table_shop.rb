# frozen_string_literal: true

class AddHostToTableShop < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :host, :string
  end
end
