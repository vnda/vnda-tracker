class IntelipostController < ApplicationController

  skip_before_action :verify_authenticity_token

  def receive_hook
    shop = Shop.find_by(intelipost_api_key: request.headers['HTTP_API_KEY'])
    tracking = shop.trackings.find_or_create_by(
      code: params[:tracking_code],
      carrier: 'intelipost'
    )
  end

end
