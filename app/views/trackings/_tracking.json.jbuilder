# frozen_string_literal: true

json.extract!(
  tracking, :id, :code, :carrier, :delivery_status, :tracker_url,
  :last_checkpoint_at, :created_at, :updated_at
)
json.url tracking_url(tracking, format: :json)
