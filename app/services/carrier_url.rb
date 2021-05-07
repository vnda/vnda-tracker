# frozen_string_literal: true

class CarrierURL
  URLS = {
    'bling' => '',
    'correios' => 'https://track.aftership.com/brazil-correios/%<code>s',
    'intelipost' => 'https://status.ondeestameupedido.com/tracking/' \
      '%<intelipost_id>s/%<code>s',
    'jadlog' => 'http://www.jadlog.com.br/siteDpd/tracking.jad?cte=%<code>s',
    'mandae' => 'https://rastreae.com.br/resultado/%<code>s',
    'melhorenvio' => 'https://melhorrastreio.com.br/rastreio/%<tracking>s',
    'tnt' => 'http://app.tntbrasil.com.br/radar/public/'\
      'localizacaoSimplificadaDetail/%<code>s',
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

    tracking_url
  end

  private

  def client_id
    return if carrier != 'totalexpress'
    return if shop.blank?

    shop.total_client_id
  end

  def intelipost_id
    return if shop.blank?

    shop.intelipost_id
  end

  def tracking
    if carrier == 'melhorenvio'
      return MelhorEnvio.new(shop).melhorenvio_tracking(code)
    end

    return Bling.new(shop).tracking_url(code) if carrier == 'bling'

    nil
  end

  def tracking_url
    tracking_value = tracking
    return tracking_value if carrier == 'bling'

    return if carrier == 'melhorenvio' && tracking_value.blank?

    format_url(tracking_value)
  end

  def format_url(tracking_value)
    format(
      URLS[carrier],
      code: code,
      reid: client_id,
      tracking: tracking_value,
      invoice: code.to_s.gsub(/\D/, ''),
      intelipost_id: intelipost_id
    )
  end
end
