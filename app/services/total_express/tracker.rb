# frozen_string_literal: true

module TotalExpress
  class Tracker < Base
    attr_reader :shop

    def initialize(shop)
      @shop = shop
    end

    def status(code)
      {
        date: Time.current,
        status: TotalExpress::DocumentReader.parse(
          shop: shop,
          code: code
        )
      }
    end

    def events(tracking_code)
      [status(tracking_code)]
    end
  end
end
