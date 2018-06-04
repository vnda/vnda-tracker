# frozen_string_literal: true

class CreateShops < ActiveRecord::Migration[5.0]
  def change
    create_table :shops do |t|
      t.string :name
      t.string :token

      t.timestamps
    end
  end
end
