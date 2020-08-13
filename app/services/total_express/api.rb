# frozen_string_literal: true

module TotalExpress
  class Api
    WSDL_URL = 'https://edi.totalexpress.com.br/webservice24.php?wsdl'

    Error = Class.new(TotalExpress::Error)
    TrackerError = Class.new(TotalExpress::Error)

    def initialize(shop)
      @shop = shop
    end

    def read
      @response = client.call(
        :obter_tracking,
        soap_action: 'ObterTracking',
        message: params_builder
      )
      parsed_return
    rescue Savon::Error => e
      raise Error, e.message
    end

    private

    def client
      Savon.client(
        wsdl: WSDL_URL,
        basic_auth: credentials,
        pretty_print_xml: true,
        log_level: :debug
      )
    end

    def collect_lots
      @response.body.dig(
        :obter_tracking_response,
        :obter_tracking_response,
        :array_lote_retorno,
        :item
      )
    end

    def parsed_return
      collect_lots.map do |item|
        item.dig(:array_encomenda_retorno, :item)
      end.flatten
    end

    def params_builder
      {
        'ObterTrackingRequest' => {
          'DataConsulta' => Time.current.strftime('%Y-%m-%d')
        }
      }
    end

    def credentials
      [@shop.total_user, @shop.total_password]
    end
  end
end
