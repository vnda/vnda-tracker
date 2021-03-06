# frozen_string_literal: true

class DeliveryCenter
  attr_reader :last_response

  def initialize(shop)
    @shop = shop
    @token = shop.delivery_center_token
  end

  def status(tracking_code)
    response = request(tracking_code)
    @last_response = response.body if response
    event = parse(response.body) if response&.body.present?

    return { date: nil, status: 'pending', message: nil } unless event

    {
      date: event['dtStatusUpdate'].to_datetime,
      status: parse_status(event),
      message: message(event)
    }
  end

  def events(_tracking_code)
    []
  end

  def parse_status(event)
    return 'delivered' if event['dtOrderDelivered'].present?

    'in_transit'
  end

  def validate_tracking_code(tracking_code)
    return false unless @shop.delivery_center_enabled

    tracking_code.match?(Regexp.new(@shop.mandae_pattern))
  end

  private

  def request(tracking_code)
    Excon.get(
      "https://api.deliverycenter.com/oms/v1/order/#{tracking_code}",
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@token}"
      }
    )
  rescue Excon::Errors::Error => e
    Sentry.capture_exception(e, extra: { tracking_code: tracking_code })
  end

  def parse(json)
    hash = JSON.parse(json)
    return unless hash

    hash
  end

  def message(event)
    return unless event['routeDistance'].to_i.positive?

    "#{event['routeDistance']} metros restantes"
  end
end
