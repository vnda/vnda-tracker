# frozen_string_literal: true

class Jadlog
  attr_reader :last_response

  def initialize(shop)
    @shop = shop
    @token = shop.jadlog_password
  end

  def status(tracking_code)
    response = request(tracking_code)
    @last_response = response.body
    event = parse(response.body)
    return { date: nil, status: 'pending', message: nil } unless event

    {
      date: "#{event['data']} -3UTC".to_datetime,
      status: parse_status(event['status']),
      message: event['status']
    }
  end

  def events(tracking_code)
    [status(tracking_code)]
  end

  def parse_status(status)
    {
      'EMISSAO' => 'in_transit',
      'ENTRADA' => 'in_transit',
      'TRANSFERENCIA' => 'in_transit',
      'EM ROTA' => 'out_of_delivery',
      'ENTREGUE' => 'delivered'
    }.fetch(status, 'exception')
  end

  def self.validate_tracking_code(shop, code)
    return false unless shop
    return false unless shop.jadlog_enabled

    code.match?(/^[0-9]{8,14}$/)
  end

  private

  def request(tracking_code)
    Excon.post(
      'http://www.jadlog.com.br/embarcador/api/tracking/consultar',
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@token}"
      },
      body: { 'consulta' => [{ 'shipmentId' => tracking_code }] }.to_json
    )
  rescue Excon::Errors::Error => e
    Honeybadger.notify(e, context: { tracking_code: tracking_code })
  end

  def parse(json)
    hash = JSON.parse(json)
    return unless hash['consulta']

    tracking = hash['consulta'].first

    return if tracking['error'].present?

    tracking['tracking']['eventos'].find do |e|
      e['status'] == tracking['tracking']['status']
    end
  end
end
