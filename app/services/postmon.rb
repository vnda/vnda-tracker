# frozen_string_literal: true

class Postmon
  URL = 'http://api.postmon.com.br/v1/rastreio/ect'

  attr_reader :last_response

  def status(tracking_code)
    begin
      response = Excon.get("#{URL}/#{tracking_code}", expects: [200, 201])
      @last_response = response.body
      hash = JSON.parse(response.body)
    rescue Excon::Errors::Error, JSON::ParserError => e
      hash = {}
      Sentry.capture_exception(e, extra: { tracking_code: tracking_code })
    end

    last_event = hash['historico']&.last

    return { date: nil, status: 'pending', message: nil } unless last_event

    {
      date: "#{last_event['data']} -3UTC".to_datetime,
      status: parse_status(last_event['situacao']),
      message: last_event['detalhes']
    }
  end

  def events(tracking_code)
    [status(tracking_code)]
  end

  def parse_status(status)
    if /Objeto postado/.match?(status)
      'in_transit'
    elsif /Postado depois do hor.*rio limite da ag.*ncia/.match?(status)
      'in_transit'
    elsif /Objeto encaminhado/.match?(status)
      'in_transit'
    elsif /Saiu para Entrega/.match?(status)
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
    elsif /Objeto saiu para entrega ao destinat.*rio/.match?(status)
      'out_of_delivery'
    elsif /Objeto entregue/.match?(status)
      'delivered'
    elsif status == 'Objeto devolvido ao remetente'
      'expired'
    else
      'exception'
    end
  end
end
