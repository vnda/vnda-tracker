# frozen_string_literal: true

require 'excon'

class Notify
  include Sidekiq::Worker
  sidekiq_options retry: 10, dead: false

  def perform(tracking_id)
    tracking = Tracking.find(tracking_id)
    return false if tracking.shop.notification_url.blank?

    Excon.post(tracking.shop.notification_url,
      body: tracking.to_json,
      headers: { 'Content-Type' => 'application/json' })
  end
end
