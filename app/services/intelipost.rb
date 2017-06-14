require 'httparty'

class Intelipost
  include HTTParty

  def initialize(shop)
    @base_uri = "api.intelipost.com.br"
    @token = shop.intelipost_api_key
    @headers = { "Content-Type"=> "application/json", "Accept"=> "*/*", "api-key"=> @token }
  end

  def status(code)
    response = get("https://#{@base_uri}/api/v1/shipment_order/#{code}")

    package_response = response['content']['shipment_order_volume_array'][0] if response['status'] == 'OK'

    date, text = if response['status'] == 'OK'
      [
        package_response['delivered_date'] || Time.now,
        parse_status(package_response['shipment_order_volume_state_localized'])
      ]
    else
      [Time.now, "pending"]
    end


    { date: "#{date} -3UTC".to_datetime, status: text }
  end

  private

  def get(url)
    JSON.parse(self.class.get(url, { headers: @headers }).body)
  end

  def parse_status(status)
    {
      'Criado' => 'pending',
      'Pronto para envio' => 'pending',
      'Despachado' => 'in_transit',
      'Em trânsito' => 'in_transit',
      'Saiu para Entrega' => 'out_of_delivery',
      'Entregue' => 'delivered',
      'Cancelado' => 'expired',
    }.fetch(status, 'expection')
  end

end
