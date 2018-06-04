# frozen_string_literal: true

class Postmon
  URL = 'http://api.postmon.com.br/v1/rastreio/ect'

  def status(tracking_code)
    begin
      response = Excon.get("#{URL}/#{tracking_code}", expects: [200, 201])
      hash = JSON.parse(response.body)
    rescue Excon::Errors::Error, JSON::ParserError => e
      hash = {}
      Honeybadger.notify(e, context: { tracking_code: tracking_code })
    end

    date, status =
      if hash['historico']
        last_event = hash['historico'].last
        [
          "#{last_event['data']} -3UTC".to_datetime,
          parse_status(last_event['situacao'])
        ]
      else
        [nil, 'pending']
      end

    { date: date, status: status }
  end

  def parse_status(status)
    if status == 'Objeto postado'
      'in_transit'
    elsif /Postado depois do hor.*rio limite da ag.*ncia/.match?(status)
      'in_transit'
    elsif status == 'Objeto encaminhado'
      'in_transit'
    elsif status == 'Saiu para Entrega'
      'out_of_delivery'
    elsif /A entrega n.*o pode ser efetuada/.match?(status)
      'out_of_delivery'
    elsif /A entrega n.*o pode ser efetuada - Carteiro n.*o atendido/.match?(status)
      'out_of_delivery'
    elsif /A entrega ocorrer.* no prox dia .til/.match?(status)
      'out_of_delivery'
    elsif /Logradouro com numera.*o irregular/.match?(status)
      'out_of_delivery'
    elsif /Coleta ou entrega de objeto n.*o efetuada/.match?(status)
      'out_of_delivery'
    elsif /Tentativa de entrega não efetuada/.match?(status)
      'out_of_delivery'
    elsif /Sa.*da para entrega cancelada/.match?(status)
      'out_of_delivery'
    elsif /Objeto entregue ao destinat.*rio/.match?(status)
      'delivered'
    elsif status == 'Objeto entregue'
      'delivered'
    elsif status == 'Objeto devolvido ao remetente'
      'expired'
    else
      'expection'
    end
  end
end
