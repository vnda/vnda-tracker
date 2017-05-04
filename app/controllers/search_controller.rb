class SearchController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_tracking, only: [:show, :edit, :update, :destroy]

  def show
  end

  private
    def set_tracking
      @tracking = scopped_trackings.find_by(code: params[:code])
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
