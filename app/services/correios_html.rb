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
    'Objeto em trânsito' => 'in_transit',
    'Objeto entregue' => 'delivered',
    'Objeto devolvido' => 'expired'
  }.freeze

  attr_reader :last_response

  def status(tracking_code)
    event = events(tracking_code).first
    return { date: nil, status: 'pending', message: nil } unless event

    event
  end

  def events(tracking_code)
    @events ||= {}
    @events[tracking_code] ||= begin
      response = request(tracking_code)

      CorreiosHistory.create(
        code: tracking_code,
        response_body: response.body.encode,
        response_status: response.status
      )

      parse(response.body)
    end
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
  rescue Excon::Errors::Error => e
    Honeybadger.notify(e, context: { tracking_code: tracking_code })
  end

  def parse(html)
    n = Nokogiri::HTML(html)
    lines = n.css('table.listEvent tr')
    @last_response = lines.text
    return [] unless lines.any?

    parse_lines(lines)
  end

  def parse_lines(lines)
    lines.map do |line|
      {
        date: parse_event_time(line.css('td.sroDtEvent').text),
        status: parse_status(line.css('td.sroLbEvent').text.strip),
        message: line.css('td.sroLbEvent').text.strip
      }
    end
  end

  def parse_event_time(text)
    array = text.split("\n").select(&:present?).map(&:strip)
    date, time, _city = array
    "#{date} #{time} -3UTC".to_datetime
  end
end
