# frozen_string_literal: true

class AddSlugToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :slug, :string
  end
end
