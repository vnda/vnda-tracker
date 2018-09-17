# frozen_string_literal: true

class CorreiosHtml
  URL = 'https://www2.correios.com.br/sistemas/rastreamento/resultado_semcont' \
    'ent.cfm'

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
    array = text.split("\r\n").select(&:present?).map(&:strip)
    date, time, _city = array
    "#{date} #{time}".to_datetime
  end

  def parse_status(text)
    {
      'Objeto postado' => 'in_transit',
      'Objeto encaminhado' => 'in_transit',
      'Objeto saiu para entrega ao destinatário' => 'out_of_delivery',
      'Objeto entregue ao destinatário' => 'delivered',
      'Objeto devolvido ao remetente' => 'expired'
    }.fetch(text, 'exception')
  end
end
