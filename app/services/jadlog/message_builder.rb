# frozen_string_literal: true

module Jadlog
  class MessageBuilder
    attr_reader :shop, :registered_cnpj, :password, :order_code

    def self.build(shop:, order_code:)
      new(shop: shop, order_code: order_code).build
    end

    def initialize(shop:, order_code:)
      @shop = shop
      @registered_cnpj = shop.jadlog_registered_cnpj
      @password = shop.jadlog_password
      @order_code = order_code
    end

    def build
      {
        'CodCliente': registered_cnpj,
        'Password': password,
        'NDs': order_code
      }
    end
  end
end
