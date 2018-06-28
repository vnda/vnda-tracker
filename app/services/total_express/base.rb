# frozen_string_literal: true

module TotalExpress
  class Base
    def initialize(shop)
      @shop = shop
    end

    private

    def carrier
      @carrier ||= Carrier.discover(code)
    end

    def tracking_url
      CarrierURL.fetch(
        carrier: carrier,
        code: code,
        shop: @shop
      )
    end
  end
end
