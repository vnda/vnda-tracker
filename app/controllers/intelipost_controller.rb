# frozen_string_literal: true

class IntelipostController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate!

  def create
    @shop = Shop.find_by!(intelipost_api_key: request.headers['api-key'])

    tracking = @shop.trackings.find_or_create_by!(
      code: params['tracking_code'],
      carrier: 'intelipost',
      package: params['order_number'],
      tracker_url: discover_tracker_url
    )

    render json: tracking.to_json, status: 204
  end

  private

  def discover_tracker_url
    CarrierURL.fetch(
      carrier: 'intelipost',
      code: params['order_number'],
      shop: @shop
    )
  end
end
