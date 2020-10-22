# frozen_string_literal: true

module Vnda
  class NotificationTracking
    def initialize(shop)
      @api = Vnda::Api.new(shop.host)
    end

    def dispatch(params)
      @api.post(
        '/notifications/trackings',
        body: params.to_json,
        expects: 200
      )
    end
  end
end
