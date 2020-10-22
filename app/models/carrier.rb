# frozen_string_literal: true

class Carrier
  UnsupportedCarrierError = Class.new(StandardError)

  CARRIERS = {
    'tnt' => Tnt,
    'intelipost' => Intelipost,
    'jadlog' => Jadlog,
    'loggi' => Loggi,
    'mandae' => Mandae,
    'melhorenvio' => MelhorEnvio,
    'totalexpress' => TotalExpress::Tracker
  }.freeze

  DISCOVERS = {
    'correios' => Correios,
    'tnt' => Tnt,
    'jadlog' => Jadlog,
    'loggi' => Loggi,
    'mandae' => Mandae,
    'melhorenvio' => MelhorEnvio,
    'totalexpress' => TotalExpress::Tracker
  }.freeze

  def initialize(shop, carrier)
    @shop = shop
    @carrier = carrier
  end

  delegate :status, :events, :last_response, to: :service

  def self.discover(code, shop)
    # Intelipost discovers this in intelipost_controller
    DISCOVERS.each do |discover|
      return discover[0] if discover[1].validate_tracking_code(shop, code)
    end

    'unknown'
  end

  def self.url(carrier:, code:, shop: nil)
    CarrierURL.fetch(
      carrier: carrier,
      code: code,
      shop: shop
    )
  end

  def service
    return correios_service if @carrier == 'correios'

    unless CARRIERS.key?(@carrier)
      raise UnsupportedCarrierError, "Carrier #{@carrier} is unsupported"
    end

    CARRIERS[@carrier].new(@shop)
  end

  protected

  def correios_service
    @correios_service ||= begin
      return CorreiosHtml.new if ENV['CORREIOS_DATA_FROM'] == 'html'
      return Postmon.new if ENV['CORREIOS_DATA_FROM'] == 'postmon'

      Correios.new
    end
  end
end
