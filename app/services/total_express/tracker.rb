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
  end
end
