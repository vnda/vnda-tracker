# frozen_string_literal: true

module Jadlog
  class Tracker
    attr_reader :shop

    WSDL_URL = 'http://www.jadlog.com/JadlogEdiWs/services/TrackingBean?WSDL'

    def initialize(shop)
      @shop = shop
    end

    def status(order_code)
      body = Jadlog::MessageBuilder.build(shop: shop, order_code: order_code)
      response = client.call(:consultar, message: body)
      success, package_status = Jadlog::Parser.parse(response.body)
      status_text = success ? parse_status(package_status) : package_status
      response(status_text)
    end

    def parse_status(status)
      {
        'EMISSAO' => 'in_transit',
        'ENTRADA' => 'in_transit',
        'TRANSFERENCIA' => 'in_transit',
        'EM ROTA' => 'out_of_delivery',
        'ENTREGUE' => 'delivered'
      }.fetch(status, 'expection')
    end

    private

    def response(status_text)
      {
        date: Time.current,
        status: status_text
      }
    end

    def client
      @client ||= Savon.client(
        wsdl: WSDL_URL,
        pretty_print_xml: true,
        log_level: :debug,
        log: Rails.env.development?
      )
    end
  end
end
