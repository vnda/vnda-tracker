class AddNotificationUrlToShops < ActiveRecord::Migration[5.0]
  def change
    add_column :shops, :notification_url, :string
  end
end
