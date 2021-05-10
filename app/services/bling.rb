# frozen_string_literal: true

class Bling
  attr_reader :last_response

  Error = Class.new(StandardError)
  OrderNumberError = Class.new(Error)
  NotFound = Class.new(Error)

  def initialize(shop)
    @shop = shop
    @api_key = shop.bling_api_key
  end

  def status(tracking_code)
    package = @shop.trackings.find_by(code: tracking_code)&.package

    raise NotFound, 'Tracking not found' unless package

    response = request(package)
    event = parse(response) if response.present?
    return { date: nil, status: 'pending', message: nil } unless event

    {
      date: event['dataSaida']&.to_datetime,
      status: parse_status(event['situacao']),
      message: event['situacao']
    }
  end

  def events(tracking_code)
    [status(tracking_code)]
  end

  def self.validate_tracking_code(shop, code)
    return false unless shop
    return false unless shop.bling_enabled

    code.present?
  end

  def tracking_url(package)
    response = request(package)
    event = parse(response)
    event&.dig('transporte', 'volumes', 0, 'volume', 'urlRastreamento')
  end

  private

  def request(package)
    @last_response = Excon.get(
      "https://bling.com.br/Api/v2/pedido/#{order_number(package)}/json",
      query: { apikey: @api_key },
      expects: 200
    ).body
  rescue Excon::Errors::Error => e
    Sentry.capture_exception(e, extra: { package: package })
  end

  def parse(json)
    hash = JSON.parse(json)
    return if hash.dig('retorno', 'erros').present?

    hash.dig('retorno', 'pedidos', 0, 'pedido')
  end

  def parse_status(status)
    {
      @shop.bling_status_in_transit => 'in_transit',
      @shop.bling_status_delivered => 'delivered'
    }.fetch(status, 'pending')
  end

  def order_number(package)
    order_code = package.split('-').first

    hub_order = find_from_hub(order_code)

    unless hub_order['remote_code']
      raise OrderNumberError, 'Remote order number is mandatory'
    end

    hub_order['remote_code']
  end

  def find_from_hub(order_code)
    Vnda::Hub.new(@shop.host).get("orders/#{order_code}")
  end
end
