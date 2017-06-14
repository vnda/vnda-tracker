class SearchController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_tracking, only: [:show, :edit, :update, :destroy]

  def show
    head(404) unless @tracking
  end

  private
    def set_tracking
      @tracking =
        scopped_trackings
        .where('code = :tracking OR package = :package',
          tracking: params[:tracking_code] || params[:code],
          package: params[:package]
        )
        .first
    end

    def scopped_trackings
      shop = if params[:token].present?
        Shop.where(token: params[:token]).first
      else
        Shop.find(params[:shop_id])
      end
      @trackings ||= shop.trackings
    end
end
