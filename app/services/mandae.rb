# frozen_string_literal: true

class Mandae
  STATUSES = {
    'Encomenda coletada' => 'in_transit',
    'Recebida na Mandaê' => 'in_transit',
    'Encomenda encaminhada' => 'in_transit',
    'Processo iniciado pela transportadora' => 'in_transit',
    'Processada na unidade da transportadora' => 'in_transit',
    'Recebida na unidade da transportadora' => 'in_transit',
    'Rota final' => 'in_transit',
    'Redespachado pelos Correios' => 'in_transit',
    'Disponível para retirada na unidade da transportadora' =>
      'out_of_delivery',
    'Nova entrega agendada' => 'out_of_delivery',
    'Destinatário ausente' => 'out_of_delivery',
    'Pedido entregue' => 'delivered',
    'Entrega realizada' => 'delivered'
  }.freeze

  attr_reader :last_response

  def initialize(shop)
    @shop = shop
    @token = shop.mandae_token
  end

  def status(tracking_code)
    response = request(tracking_code)
    event = parse(response) if response.present?
    unless event && event['date']
      return { date: nil, status: 'pending', message: nil }
    end

    {
      date: "#{event['date']} -3UTC".to_datetime,
      status: parse_status(event['name']),
      message: event['description']
    }
  end

  def events(tracking_code)
    [status(tracking_code)]
  end

  def parse_status(status)
    STATUSES.fetch(status, 'exception')
  end

  def self.validate_tracking_code(shop, tracking_code)
    return false unless shop
    return false unless shop.mandae_enabled
    return false if shop.mandae_pattern.blank?

    tracking_code.match?(Regexp.new(shop.mandae_pattern))
  end

  private

  def request(tracking_code)
    @last_response = Excon.get(
      "https://api.mandae.com.br/v2/trackings/#{tracking_code}",
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => @token
      }
    ).body
  rescue Excon::Errors::Error => e
    Sentry.capture_exception(e, extra: { tracking_code: tracking_code })
  end

  def parse(json)
    hash = JSON.parse(json)
    return if hash['error'].present?

    hash['events'].first
  end
end
