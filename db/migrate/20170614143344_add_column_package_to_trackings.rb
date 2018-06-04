# frozen_string_literal: true

class AddColumnPackageToTrackings < ActiveRecord::Migration[5.0]
  def change
    add_column :trackings, :package, :string
  end
end
