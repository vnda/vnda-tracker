# frozen_string_literal: true

module TotalExpress
  class Tracker
    def initialize(shop)
      @shop = shop
    end

    def status(code)
      TotalExpress::StatusReader.new(@shop, code).parse
    end

    def events(tracking_code)
      [status(tracking_code)]
    end

    def last_response
      nil
    end

    def self.validate_tracking_code(_shop, code)
      code.match?(/^VN\w{1,}$/)
    end
  end
end
