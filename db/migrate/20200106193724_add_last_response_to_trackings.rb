# frozen_string_literal: true

class AddLastResponseToTrackings < ActiveRecord::Migration[5.2]
  def change
    add_column :trackings, :last_response, :text
  end
end
