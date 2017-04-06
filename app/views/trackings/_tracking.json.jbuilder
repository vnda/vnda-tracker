json.extract! tracking, :id, :code, :carrier, :notification_url, :delivery_status, :url, :created_at, :updated_at
json.url tracking_url(tracking, format: :json)
