# frozen_string_literal: true

module TotalExpress
  class DocumentReader < Base
    attr_reader :shop, :code

    def self.parse(shop:, code:)
      new(shop: shop, code: code).parse
    end

    def initialize(shop:, code:)
      @shop = shop
      @code = code
    end

    def parse
      return 'exception' if last_status.blank?

      parse_status(last_status)
    end

    private

    def html_body
      @html_body ||= Nokogiri::HTML(
        Excon.get(tracking_url).body
      )
    end

    def last_status
      return if table.blank?

      table.css('tr td')[-1].text.gsub(/^[\s\t]*|[\s\t]*\n/, '')
    end

    def table
      html_body.css('table#tabela1')
    end

    def parse_status(status)
      case status.to_s.downcase
      when /recebido/, /transferencia/
        'in_transit'
      when /processo de entrega/, /separado para o roteiro/,
        /estabelecimento fechado/
        'out_of_delivery'
      when /entrega realizada/
        'delivered'
      end
    end
  end
end
