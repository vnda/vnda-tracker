class Carrier
  def initialize(carrier)
    @carrier = carrier
  end

  def status(code)
    service.status(code)
  end

  def self.discover(code)
    return "correios" if code =~ /[A-Z]{2}[0-9]{9}[A-Z]{2}/
    "unknown"
  end

  def self.url(carrier, code)
    return "https://track.aftership.com/#{code}" if carrier == "correios"
    ""
  end

  protected

  def service
    @service ||= if @carrier == "correios"
      Correios.new
    else
      raise "Unsupported Carrier"
    end
  end
end
