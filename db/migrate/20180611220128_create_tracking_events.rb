# frozen_string_literal: true

class CreateTrackingEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :tracking_events do |t|
      t.string :delivery_status
      t.datetime :checkpoint_at
      t.string :message
      t.text :response_data
      t.references :tracking
      t.timestamps
    end
  end
end
