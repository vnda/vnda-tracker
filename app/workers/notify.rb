# frozen_string_literal: true

require 'excon'

class Notify
  include Sidekiq::Worker
  sidekiq_options retry: 10, dead: false

  def perform(tracking_id)
    tracking = Tracking.find(tracking_id)
    return false if tracking.shop.notification_url.blank?

    res = send_notification(tracking.shop.notification_url, tracking.to_json)

    tracking.notifications.create(
      url: tracking.shop.notification_url,
      data: tracking.to_json,
      response: res.body
    )

    true
  end

  private

  def send_notification(url, json)
    uri = URI(url)
    api = Vnda::Api.new(uri.host)
    api.post(
      uri.path,
      body: json,
      expects: 200
    )
  end
end
