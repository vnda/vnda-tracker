# frozen_string_literal: true

require 'excon'

class Notify
  include Sidekiq::Worker
  sidekiq_options retry: 10, dead: false

  def perform(tracking_id)
    tracking = Tracking.find(tracking_id)
    shop = tracking.shop

    response = Vnda::NotificationTracking.new(shop).dispatch(tracking)

    tracking.notifications.create(
      url: response.host,
      data: tracking.to_json,
      response: response.body
    )

    true
  end
end
