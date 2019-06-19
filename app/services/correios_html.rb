# frozen_string_literal: true

class CorreiosHtml
  URL = 'https://www2.correios.com.br/sistemas/rastreamento/resultado.cfm'

  STATUS_MAPPING = {
    'Objeto postado' => 'in_transit',
    'Postado depois do hor.*rio limite da ag.*ncia' => 'in_transit',
    'Objeto encaminhado' => 'in_transit',
    'Saiu para Entrega' => 'out_of_delivery',
    'A entrega n.*o pode ser efetuada' => 'out_of_delivery',
    'A entrega ocorrer.* no prox dia .til' => 'out_of_delivery',
    'Logradouro com numera.*o irregular' => 'out_of_delivery',
    'Coleta ou entrega de objeto n.*o efetuada' => 'out_of_delivery',
    'Tentativa de entrega não efetuada' => 'out_of_delivery',
    'Sa.*da para entrega cancelada' => 'out_of_delivery',
    'Objeto saiu para entrega ao destinat.*rio' => 'out_of_delivery',
    'Objeto entregue' => 'delivered',
    'Objeto devolvido' => 'expired'
  }.freeze

  def status(tracking_code)
    begin
      response = request(tracking_code)
    rescue Excon::Errors::Error => e
      Honeybadger.notify(e, context: { tracking_code: tracking_code })
    end

    event = parse(response.body)
    return { date: nil, status: 'pending', message: nil } unless event

    event
  end

  def parse_status(text)
    STATUS_MAPPING.each do |regex, status|
      return status if Regexp.new(regex).match?(text)
    end

    'exception'
  end

  private

  def request(tracking_code)
    Excon.post(
      URL,
      body: URI.encode_www_form(objetos: tracking_code),
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )
  end

  def parse(html)
    n = Nokogiri::HTML(html)
    lines = n.css('table.listEvent tr')
    return unless lines.any?

    line = lines.first
    {
      date: parse_event_time(line.css('td.sroDtEvent').text),
      status: parse_status(line.css('td.sroLbEvent').text.strip),
      message: line.css('td.sroLbEvent').text.strip
    }
  end

  def parse_event_time(text)
    array = text.split("\n").select(&:present?).map(&:strip)
    date, time, _city = array
    "#{date} #{time} -3UTC".to_datetime
  end
end
