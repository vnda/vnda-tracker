require 'httparty'

class Intelipost
  include HTTParty

  def initialize(shop)
    @base_uri = "api.intelipost.com.br"
    @token = shop.intelipost_api_key
    @headers = { "Content-Type"=> "application/json", "Accept"=> "*/*", "api-key"=> @token }
  end

  def shipment_order(order_number)
    get("https://#{@base_uri}/api/v1/shipment_order/#{order_number}")
  end

  private

  def get(url)
    JSON.parse(self.class.get(url, { headers: @headers }).body)
  end

end
