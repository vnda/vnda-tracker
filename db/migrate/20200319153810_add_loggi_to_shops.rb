# frozen_string_literal: true

class AddLoggiToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :loggi_enabled, :boolean
    add_column :shops, :loggi_token, :string
    add_column :shops, :loggi_email, :string
    add_column :shops, :loggi_shop_id, :integer
    add_column :shops, :loggi_api_url, :string
    add_column :shops, :loggi_pattern, :string
  end
end
