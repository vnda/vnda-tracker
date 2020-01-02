# frozen_string_literal: true

class DeliveryCenter
  def initialize(shop)
    @shop = shop
    @token = shop.delivery_center_token
  end

  def status(tracking_code)
    response = request(tracking_code)
    event = parse(response.body)

    return { date: nil, status: 'pending', message: nil } unless event

    {
      date: event['dtStatusUpdate'].to_datetime,
      status: parse_status(event),
      message: message(event)
    }
  end

  def parse_status(event)
    return 'delivered' if event['dtOrderDelivered'].present?

    'in_transit'
  end

  def accept?(tracking_code)
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
    Honeybadger.notify(e, context: { tracking_code: tracking_code })
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
