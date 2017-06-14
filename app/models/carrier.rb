class Carrier
  def initialize(carrier)
    @carrier = carrier
  end

  def status(code)
    service.status(code)
  end

  def self.discover(code)
    return "correios" if code =~ /[A-Z]{2}[0-9]{9}[A-Z]{2}/
    return "tnt" if code =~ /^.{12}$/
    "unknown"
  end

  def self.url(shop, carrier, code)
    return "https://track.aftership.com/#{code}" if carrier == "correios"
    return "http://app.tntbrasil.com.br/radar/public/localizacaoSimplificadaDetail/#{code}" if carrier == "tnt"
    return "https://status.ondeestameupedido.com/tracking/#{shop.intelipost_id}/#{code}" if carrier == "intelipost"
    ""
  end

  protected

  def service
    @service ||= if @carrier == "correios"
      Correios.new
    elsif @carrier == "tnt"
      Tnt.new
    else
      raise "Unsupported Carrier"
    end
  end
end
