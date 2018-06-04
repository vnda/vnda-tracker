# frozen_string_literal: true

class AddForwardToIntelipostToShops < ActiveRecord::Migration[5.0]
  def change
    add_column :shops, :forward_to_intelipost, :boolean, default: false
  end
end
