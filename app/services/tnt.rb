require 'savon'

class Tnt
  def status(email, cnpj, order_code)
    wsdl_url = "http://ws.tntbrasil.com.br/servicos/Localizacao?wsdl"

    client = Savon.client do
      wsdl wsdl_url
      log true
      pretty_print_xml true
    end
    puts "WSDL url: #{wsdl_url}"

    message = {
      "in0" => {
        "cnpj" => cnpj,
        "pedido" => order_code,
        "usuario" => email,
      }
    }

    response = client.call(:localiza_mercadoria, message: message)
    hash = Hash.from_xml(response.to_xml)

    output = hash["Envelope"]["Body"]["localizaMercadoriaResponse"]["out"]
    error_message = output["erros"]["string"] rescue nil

    date, text = if error_message.present?
      [Time.now, error_message]
    elsif output["localizacao"] == "ENTREGA REALIZADA"
      [output["dataEntrega"], output["localizacao"]]
    else
      [Time.now, "unknown"]
    end

    {date: "#{date} -3UTC".to_datetime, status: parse_status(text)}
  end

  def parse_status(status)
    {
      "Nenhum registro encontrado." => "pending",
      "" => "in_transit",
      "" => "out_of_delivery",
      "ENTREGA REALIZADA" => "delivered"
    }.fetch(status, "expection")
  end
end
