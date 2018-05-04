# frozen_string_literal: true

module Jadlog
  class Parser
    attr_reader :response

    ERROR_CODES = [
      '-1', '-99'
    ].freeze

    def self.parse(response)
      new(response).parse
    end

    def initialize(response)
      @response = response
    end

    def parse
      return [false, error] if error.present?
      [true, response_xml.at_css('Status').text]
    end

    private

    def error
      @error ||= begin
        error_code = response_xml.at_css('Retorno')
        return if error_code.blank?
        response_xml.at_css('Mensagem').text
      end
    end

    def response_xml
      @response_xml ||= Nokogiri::XML(
        response[:consultar_response][:consultar_return]
      )
    end
  end
end
