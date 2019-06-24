# frozen_string_literal: true

class SearchController < ApplicationController
  layout 'public', only: :show

  skip_before_action :verify_authenticity_token
  before_action :set_tracking, only: %i[show edit update destroy]

  def show
    head(404) unless @tracking
  end

  private

  def set_tracking
    code = params[:tracking_code] || params[:code]
    package = params[:package].presence
    condition = code && package ? 'AND' : 'OR'

    @tracking =
      scopped_trackings
        .where("code = :tracking #{condition} package = :package",
          tracking: code,
          package: package)
        .first
  end

  def scopped_trackings
    shop_query = {
      token: params[:token].presence,
      slug: params[:shop_name].presence,
      id: params[:shop_id].presence
    }.compact
    shop = Shop.find_by(shop_query)
    @trackings ||= shop.trackings
  end
end
