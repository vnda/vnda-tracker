# frozen_string_literal: true

require 'savon'

class Tnt
  def initialize(shop)
    @email = shop.tnt_email
    @cnpj = shop.tnt_cnpj
  end

  def status(order_code)
    wsdl_url = 'http://ws.tntbrasil.com.br/servicos/Localizacao?wsdl'

    client = Savon.client do
      wsdl wsdl_url
      log true
      pretty_print_xml true
    end
    puts "WSDL url: #{wsdl_url}"

    message = {
      'in0' => {
        'cnpj' => @cnpj,
        'pedido' => order_code,
        'usuario' => @email
      }
    }

    response = client.call(:localiza_mercadoria, message: message)
    hash = Hash.from_xml(response.to_xml)

    output = hash['Envelope']['Body']['localizaMercadoriaResponse']['out']
    error_message = begin
                      output['erros']['string']
                    rescue StandardError
                      nil
                    end

    date, text = if error_message.present?
                   [Time.now, error_message]
                 elsif output['localizacao'] == 'ENTREGA REALIZADA'
                   [output['dataEntrega'], output['localizacao']]
                 else
                   [Time.now, 'unknown']
    end

    { date: "#{date} -3UTC".to_datetime, status: parse_status(text) }
  end

  def parse_status(status)
    {
      'Nenhum registro encontrado.' => 'pending',
      'ENTREGA REALIZADA' => 'delivered'
    }.fetch(status, 'expection')
  end
end
