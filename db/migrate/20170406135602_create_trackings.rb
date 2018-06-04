# frozen_string_literal: true

class CreateTrackings < ActiveRecord::Migration[5.0]
  def change
    create_table :trackings do |t|
      t.string :code
      t.string :carrier
      t.string :notification_url
      t.string :delivery_status
      t.string :url
      t.references :shop

      t.timestamps
    end
  end
end
