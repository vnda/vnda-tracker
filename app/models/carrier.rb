class Carrier
  def initialize(shop, carrier)
    @shop = shop
    @carrier = carrier
  end

  def status(code)
    service.status(code)
  end

  def self.discover(code)
    return "correios" if code =~ /[A-Z]{2}[0-9]{9}[A-Z]{2}/
    return "tnt" if code =~ /^.{12}$/
    # Intelipost discovers this in intelipost_controller
    "unknown"
  end

  def self.url(carrier, code)
    return "https://track.aftership.com/brazil-correios/#{code}" if carrier == "correios"
    return "http://app.tntbrasil.com.br/radar/public/localizacaoSimplificadaDetail/#{code}" if carrier == "tnt"
    # Intelipost discovers this in intelipost_controller
    ""
  end

  protected

  def service
    @service ||= if @carrier == "correios"
      Correios.new
    elsif @carrier == "tnt"
      Tnt.new
    elsif @carrier == "intelipost"
      Intelipost.new(@shop)
    else
      raise "Unsupported Carrier"
    end
  end
end
