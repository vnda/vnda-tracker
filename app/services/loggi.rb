# frozen_string_literal: true

class Loggi
  def initialize(shop)
    @shop = shop
  end

  def status(tracking_code)
    request(tracking_code)
  end

  def events(tracking_code)
    [status(tracking_code)]
  end

  def self.validate_tracking_code(shop, tracking_code)
    return false unless shop
    return false unless shop.loggi_enabled && shop.loggi_pattern.present?

    tracking_code.match?(Regexp.new(shop.loggi_pattern))
  end

  def parse_status(status)
    {
      'allocating' => 'in_transit',
      'accepted' => 'in_transit',
      'dropped' => 'in_transit',
      'started' => 'out_of_delivery',
      'finished' => 'delivered'
    }.fetch(status, 'exception')
  end

  private

  def request(tracking_code)
    response = Excon.post(
      @shop.loggi_api_url,
      headers: headers,
      body: request_params(tracking_code).to_json
    )

    parse(JSON.parse(response.body))
  rescue Excon::Errors::Error => e
    Honeybadger.notify(e, context: { tracking_code: tracking_code })
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "ApiKey #{@shop.loggi_email}:#{@shop.loggi_token}"
    }
  end

  def request_params(tracking_code)
    {
      'query' => "query {
        retrieveOrderWithPk(orderPk: #{tracking_code}) {
          status
          statusDisplay
          originalEta
        }
      }"
    }
  end

  def parse(hash)
    return error_hash if hash['errors'].present?

    {
      date: convert_unix_time_to_datetime(
        hash['data']['retrieveOrderWithPk']['originalEta']
      ),
      status: parse_status(hash['data']['retrieveOrderWithPk']['status']),
      message: hash['data']['retrieveOrderWithPk']['statusDisplay']
    }
  end

  def error_hash
    { date: nil, status: 'pending', message: nil }
  end

  def convert_unix_time_to_datetime(eta)
    time = Time.zone.strptime(eta.to_s, '%s')
    "#{time.strftime('%F %T')} -3UTC".to_datetime
  end
end
