# frozen_string_literal: true

class RenameUrlOfTrackings < ActiveRecord::Migration[5.0]
  def change
    rename_column :trackings, :url, :tracker_url
  end
end
