require 'faraday'
require "faraday_middleware"

class Correios
  def status(tracking_code)
    url = "http://websro.correios.com.br/sro_bin/txect01$.QueryList?P_LINGUA=001&P_TIPO=001&P_COD_UNI=#{tracking_code}"
    connection = Faraday.new(url) do |builder|
      builder.use FaradayMiddleware::FollowRedirects
      builder.adapter :net_http
    end

    begin
      body = connection.get.body
    rescue Faraday::Error::ConnectionFailed, Faraday::Error::TimeoutError
      @status = 'error'
    else
      page = Nokogiri::HTML(body)
      last_event = page.css('table').children.css('tr')
      date, text = if last_event.any?
        [last_event[1].children[0].text, last_event[1].children[2].text]
      else
        [Time.now, "unknown"]
      end
      {date: "#{date} -3UTC".to_datetime, status: parse_status(text)}
    end
  end

  def parse_status(status)
    {
      "Postado" => "in_transit",
      "Postado depois do horário limite da agência" => "in_transit",
      "Objeto ainda não chegou à unidade" => "in_transit",
      "Encaminhado" => "in_transit",
      "Saiu para entrega ao destinatário" => "out_of_delivery",
      "Entrega não efetuada por motivos operacionais" => "out_of_delivery",
      "Entrega Efetuada" => "delivered"
    }.fetch(status, "expection")
  end
end
