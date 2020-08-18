# frozen_string_literal: true

class CreateCorreiosHistory < ActiveRecord::Migration[5.2]
  def change
    create_table :correios_histories do |t|
      t.string :code, null: false
      t.text :response_body
      t.integer :response_status
      t.timestamps
    end
  end
end
