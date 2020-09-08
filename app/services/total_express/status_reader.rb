# frozen_string_literal: true

module TotalExpress
  class StatusReader
    STATUSES = {
      '102' => 'in_transit', # TRANSFERENCIA PARA:
      '103' => 'in_transit', # RECEBIDO CD DE:
      '104' => 'out_of_delivery', # PROCESSO DE ENTREGA
      '91' => 'out_of_delivery', # ENTREGA PROGRAMADA
      '21' => 'out_of_delivery', # CLIENTE AUSENTE/ ESTABELECIMENTO FECHADO
      '29' => 'out_of_delivery', # CLIENTE RETIRA NA TRANSPORTADORA
      '1' => 'delivered' # ENTREGA REALIZADA
    }.freeze

    def initialize(shop, code)
      @shop = shop
      @code = code
    end

    def parse
      return { date: nil, status: 'pending', message: nil } if last_order.blank?

      {
        date: last_order[:data_status].strftime('%Y-%m-%d %H:%M:%S %z'),
        status: STATUSES.fetch(last_order[:cod_status], 'exception'),
        message: last_order[:desc_status]
      }
    end

    private

    def orders
      TotalExpress::Api.new(@shop).read
    end

    def last_order
      return if orders.blank?

      last_order = orders.select { |order| order[:pedido] == @code }.try(:last)
      return if last_order.blank?

      items = last_order.dig(:array_status_total, :item)
      items.is_a?(Array) ? items.try(:last) : items
    end
  end
end
