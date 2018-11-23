# frozen_string_literal: true

class Carrier
  CARRIERS = {
    'tnt' => Tnt,
    'intelipost' => Intelipost,
    'jadlog' => Jadlog,
    'totalexpress' => TotalExpress::Tracker
  }.freeze

  def initialize(shop, carrier)
    @shop = shop
    @carrier = carrier
  end

  delegate :status, to: :service

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.discover(code, shop = nil)
    # Intelipost discovers this in intelipost_controller
    return 'correios' if code.match?(/^[a-zA-Z]{2}[0-9]{9}[a-zA-Z]{2}$/)
    return 'tnt' if code =~ /^.{12}$/ && shop && shop.tnt_enabled?
    return 'jadlog' if code.match?(/^[0-9]{8,14}$/)
    return 'totalexpress' if code.match?(/^VN\w{1,}$/)
    'unknown'
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def self.url(carrier:, code:, shop: nil)
    # Intelipost discovers this in intelipost_controller
    CarrierURL.fetch(
      carrier: carrier,
      code: code,
      shop: shop
    )
  end

  def service
    return correios_service if @carrier == 'correios'
    raise 'Unsupported Carrier' unless CARRIERS.key?(@carrier)
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
