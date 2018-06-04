# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate!

  protected

  def authenticate!
    unless Rails.env.development?
      if params[:token].present? && Shop.where(token: params[:token]).first
        return true
      end

      authenticate_or_request_with_http_basic do |username, password|
        username == ENV['HTTP_USER'] && password == ENV['HTTP_PASSWORD']
      end
    end
  end
end
