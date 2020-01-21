# frozen_string_literal: true

class Carrier
  UnsupportedCarrierError = Class.new(StandardError)

  CARRIERS = {
    'tnt' => Tnt,
    'intelipost' => Intelipost,
    'jadlog' => Jadlog,
    'mandae' => Mandae,
    'totalexpress' => TotalExpress::Tracker
  }.freeze

  def initialize(shop, carrier)
    @shop = shop
    @carrier = carrier
  end

  delegate :status, :events, :last_response, to: :service

  def self.discover(code, shop)
    # Intelipost discovers this in intelipost_controller
    return 'correios' if code.match?(/^[a-zA-Z]{2}[0-9]{9}[a-zA-Z]{2}$/)
    return 'tnt' if Tnt.new(shop).accept?(code)
    return 'jadlog' if code.match?(/^[0-9]{8,14}$/)
    return 'mandae' if Mandae.new(shop).accept?(code)
    return 'totalexpress' if code.match?(/^VN\w{1,}$/)

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
