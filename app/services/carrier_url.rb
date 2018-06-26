# frozen_string_literal: true

class CarrierURL
  URLS = {
    'correios' => 'https://track.aftership.com/brazil-correios/%<code>s',
    'tnt' => 'http://app.tntbrasil.com.br/radar/public/'\
      'localizacaoSimplificadaDetail/%<code>s',
    'jadlog' => 'http://www.jadlog.com.br/siteDpd/tracking.jad?cte=%<code>s',
    'totalexpress' => 'https://tracking.totalexpress.com.br/poupup_track.php?'\
      'reid=%<reid>s&pedido=%<code>s&nfiscal=%<invoice>s'
  }.freeze

  attr_reader :carrier, :code, :shop

  def self.fetch(carrier:, code:, shop: nil)
    new(carrier: carrier, code: code, shop: shop).fetch
  end

  def initialize(carrier:, code:, shop:)
    @carrier = carrier
    @code = code
    @shop = shop
  end

  def fetch
    return '' unless URLS.key?(carrier)
    format_url
  end

  private

  def client_id
    return if carrier != 'totalexpress'
    return if shop.blank?

    shop.total_client_id
  end

  def format_url
    format(
      URLS[carrier],
      code: code,
      reid: client_id,
      invoice: code.to_s.gsub(/\D/, '')
    )
  end
end
