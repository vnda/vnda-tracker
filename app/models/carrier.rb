# frozen_string_literal: true

class Carrier
  URLS = {
    'correios' => 'https://track.aftership.com/brazil-correios/%<code>s',
    'tnt' => 'http://app.tntbrasil.com.br/radar/public/'\
      'localizacaoSimplificadaDetail/%<code>s',
    'jadlog' => 'http://www.jadlog.com.br/siteDpd/tracking.jad?cte=%<code>s'
  }.freeze

  CARRIERS = {
    'tnt' => Tnt,
    'intelipost' => Intelipost,
    'jadlog' => Jadlog::Tracker
  }.freeze

  def initialize(shop, carrier)
    @shop = shop
    @carrier = carrier
  end

  def status(code)
    service.status(code)
  end

  def self.discover(code)
    # Intelipost discovers this in intelipost_controller
    return 'correios' if code.match?(/[A-Z]{2}[0-9]{9}[A-Z]{2}/)
    return 'tnt' if code =~ /^.{12}$/ && @shop.tnt_enabled?
    return 'jadlog' if code.match?(/[0-9]{8,14}/)
    'unknown'
  end

  def self.url(carrier, code)
    # Intelipost discovers this in intelipost_controller
    return '' unless URLS.key?(carrier)
    format(URLS[carrier], code: code)
  end

  def service
    return correios_service if @carrier == 'correios'
    raise 'Unsupported Carrier' unless CARRIERS.key?(@carrier)
    CARRIERS[@carrier].new(@shop)
  end

  protected

  def correios_service
    @correios_service ||= begin
      return Postmon.new if ENV['CORREIOS_FROM_POSTMON']
      Correios.new
    end
  end
end
