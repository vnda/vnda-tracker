# frozen_string_literal: true

class CreateTrackingNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :tracking_notifications do |t|
      t.string :url
      t.text :data
      t.text :response

      t.references :tracking
      t.timestamps
    end
  end
end
