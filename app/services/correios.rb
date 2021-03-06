# frozen_string_literal: true

class Correios
  URL = 'http://webservice.correios.com.br/service/rastro/Rastro.wsdl'

  attr_reader :last_response

  def status(tracking_code)
    begin
      response = send_message(:busca_eventos,
        'usuario' => 'ECT',
        'senha' => 'SRO',
        'tipo' => 'L',
        'resultado' => 'U',
        'lingua' => '101',
        'objetos' => tracking_code)
    rescue Wasabi::Resolver::HTTPError,
           Excon::Errors::Error,
           Savon::HTTPError => e
      Sentry.capture_exception(e, extra: { tracking_code: tracking_code })
      return { date: nil, status: 'pending', message: nil }
    end
    object = response.body[:busca_eventos_response][:return][:objeto]
    event = object[:evento]

    return { date: nil, status: 'pending', message: nil } unless event

    {
      date: "#{event[:data]} #{event[:hora]} -3UTC".to_datetime,
      status: parse_status("#{event[:tipo]}-#{event[:status]}"),
      message: event[:descricao]
    }
  end

  def events(tracking_code)
    [status(tracking_code)]
  end

  def parse_status(status)
    {
      'PO-01' => 'in_transit', # Postado
      'PO-09' => 'in_transit', # Postado depois do horário limite da agência
      'RO-01' => 'in_transit', # Objeto encaminhado
      'DO-01' => 'in_transit', # Objeto encaminhado
      'OEC-01' => 'out_of_delivery', # Saiu para Entrega
      'BDE-20' => 'out_of_delivery', # Não entregue - Carteiro não atendido
      'BDI-20' => 'out_of_delivery', # Não entregue - Carteiro não atendido
      'BDR-20' => 'out_of_delivery', # Não entregue - Carteiro não atendido
      'BDE-25' => 'out_of_delivery', # A entrega ocorrerá no prox dia util
      'BDI-25' => 'out_of_delivery', # A entrega ocorrerá no prox dia util
      'BDR-25' => 'out_of_delivery', # A entrega ocorrerá no prox dia util
      'BDE-34' => 'out_of_delivery', # Logradouro com numeração irregular
      'BDI-34' => 'out_of_delivery', # Logradouro com numeração irregular
      'BDR-34' => 'out_of_delivery', # Logradouro com numeração irregular
      'BDE-35' => 'out_of_delivery', # Coleta ou entrega de objeto não efetuada
      'BDI-35' => 'out_of_delivery', # Coleta ou entrega de objeto não efetuada
      'BDR-35' => 'out_of_delivery', # Coleta ou entrega de objeto não efetuada
      'BDE-46' => 'out_of_delivery', # Tentativa de entrega não efetuada
      'BDI-46' => 'out_of_delivery', # Tentativa de entrega não efetuada
      'BDR-46' => 'out_of_delivery', # Tentativa de entrega não efetuada
      'BDE-47' => 'out_of_delivery', # Saída para entregacancelad
      'BDI-47' => 'out_of_delivery', # Saída para entregacancelad
      'BDR-47' => 'out_of_delivery', # Saída para entregacancelad
      'BDE-01' => 'delivered', # Objeto entregue
      'BDI-01' => 'delivered', # Objeto entregue
      'BDR-01' => 'delivered', # Objeto entregue
      'BDE-23' => 'expired', # Objeto devolvido ao remetente
      'BDI-23' => 'expired', # Objeto devolvido ao remetente
      'BDR-23' => 'expired'  # Objeto devolvido ao remetente
    }.fetch(status, 'exception')
  end

  def self.validate_tracking_code(_shop, code)
    code.match?(/^[a-zA-Z]{2}[0-9]{9}[a-zA-Z]{2}$/)
  end

  private

  def send_message(method_id, message)
    client = Savon.client(wsdl: URL, convert_request_keys_to: :none)
    request_xml = client.operation(method_id).build(message: message).to_s
    response = client.call(method_id, message: message)
    @last_response = response.to_xml
    response
  end
end
