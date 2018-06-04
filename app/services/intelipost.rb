# frozen_string_literal: true

require 'httparty'

class Intelipost
  include HTTParty

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

    date, text =
      if response['status'] == 'OK'
        [
          package_response['delivered_date'] || Time.now,
          parse_status(
            package_response['shipment_order_volume_state_localized']
          )
        ]
      else
        [Time.now, 'pending']
      end

    { date: "#{date} -3UTC".to_datetime, status: text }
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

  private

  def get(url)
    JSON.parse(self.class.get(url, headers: @headers).body)
  end

  def post(url, params)
    JSON.parse(
      self.class.post(
        url,
        body: params.to_json,
        headers: @headers
      ).body
    )
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
    }.fetch(status, 'expection')
  end
end
