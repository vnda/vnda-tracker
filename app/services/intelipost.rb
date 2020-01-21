# frozen_string_literal: true

class Intelipost
  attr_reader :last_response

  def initialize(shop)
    @base_uri = 'api.intelipost.com.br'
    @token = shop.intelipost_api_key
    @headers = {
      'Content-Type' => 'application/json',
      'Accept' => '*/*',
      'api-key' => @token
    }
  end

  def status(code)
    response = get("https://#{@base_uri}/api/v1/shipment_order/#{code}")

    if response['status'] == 'OK'
      package_response = response['content']['shipment_order_volume_array'][0]
    end

    return { date: nil, status: 'pending' } unless response['status'] == 'OK'

    event_date = package_response['delivered_date_iso'] ||
                 package_response['modified_iso']
    event_status = package_response['shipment_order_volume_state_localized']
    {
      date: event_date.to_datetime,
      status: parse_status(event_status)
    }
  end

  def events(tracking_code)
    [status(tracking_code)]
  end

  def update_tracking(package_code, code)
    return unless order_code = package_code.to_s.split('-').first

    volumes = get(
      "https://#{@base_uri}/api/v1/shipment_order/get_volumes/#{order_code}"
    )
    return unless volumes['status'] == 'OK'

    tracking_data_array = volumes['content'].map do |v|
      {
        shipment_order_volume_number: v['shipment_order_volume_number'],
        tracking_code: code
      }
    end

    params = {
      order_number: order_code,
      tracking_data_array: tracking_data_array
    }
    response = post(
      "https://#{@base_uri}/api/v1/shipment_order/set_tracking_data",
      params
    )
    response['status'] == 'OK'
  end

  def parse_status(status)
    {
      'Criado' => 'pending',
      'Pronto para envio' => 'pending',
      'Despachado' => 'in_transit',
      'Em trânsito' => 'in_transit',
      'Saiu para Entrega' => 'out_of_delivery',
      'Entregue' => 'delivered',
      'Cancelado' => 'expired'
    }.fetch(status, 'exception')
  end

  private

  def get(url)
    response = Excon.get(url, headers: @headers)
    @last_response = response.body
    JSON.parse(response.body)
  rescue JSON::ParserError
    {}
  end

  def post(url, params)
    response = Excon.post(url, body: params.to_json, headers: @headers)
    JSON.parse(response.body)
  rescue JSON::ParserError
    {}
  end
end
