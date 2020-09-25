# frozen_string_literal: true

module Vnda
  class Shop
    def initialize(shop)
      @api = Vnda::Api.new(shop.host)
    end

    def read
      response = @api.get('/shop')
      response = JSON.parse(response.body)
      response['settings']
    end
  end
end
