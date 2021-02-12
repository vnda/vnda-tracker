# frozen_string_literal: true

class MelhorEnvio
  ENVIRONMENTS = %w[sandbox production].freeze

  STATUSES = {
    'pending' => 'pending',
    'posted' => 'in_transit',
    'released' => 'in_transit',
    'delivered' => 'delivered'
  }.freeze

  DATES = {
    'pending' => 'created_at',
    'posted' => 'posted_at',
    'released' => 'generated_at',
    'delivered' => 'delivered_at'
  }.freeze

  attr_reader :last_response

  def initialize(shop)
    @shop = shop
  end

  def status(tracking_code)
    response = request(tracking_code)
    event = parse(response, tracking_code)
    return { date: nil, status: 'pending', message: nil } if event.blank?

    {
      date: event[parse_date(event['status'])].to_datetime,
      status: parse_status(event['status']),
      message: nil
    }
  end

  def events(tracking_code)
    [status(tracking_code)]
  end

  def parse_date(status)
    DATES.fetch(status, 'created_at')
  end

  def parse_status(status)
    STATUSES.fetch(status, 'exception')
  end

  def self.validate_tracking_code(shop, tracking_code)
    return false unless shop
    return false unless shop.melhor_envio_enabled

    tracking_code.match?(/^[a-z0-9\-]{36}$/)
  end

  def melhorenvio_tracking(tracking_code)
    response = request(tracking_code)
    event = parse(response, tracking_code)
    event['tracking']
  end

  private

  def token
    @token ||= Vnda::Shop.new(@shop).read['melhor_envio_access_token']
  end

  def url_environment
    if @shop.melhor_envio_environment == 'production'
      return 'melhorenvio.com.br'
    end

    'sandbox.melhorenvio.com.br'
  end

  def headers
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{token}"
    }
  end

  def request(tracking_code)
    @last_response = Excon.post(
      "https://#{url_environment}/api/v2/me/shipment/tracking",
      body: { 'orders' => [tracking_code] }.to_json,
      headers: headers
    ).body
  rescue Excon::Errors::Error => exception
    Sentry.capture_exception(exception, extra: { tracking_code: tracking_code })
    { errors: 'exception' }.to_json
  end

  def parse(json, tracking_code)
    hash = JSON.parse(json)
    return if hash.empty? || hash['errors'].present?

    hash[tracking_code]
  end
end
