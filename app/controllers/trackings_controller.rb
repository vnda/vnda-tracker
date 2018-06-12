# frozen_string_literal: true

class TrackingsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_tracking, only: %i[show edit update destroy]

  # GET /trackings
  # GET /trackings.json
  def index
    @trackings = scopped_trackings.order(created_at: :desc)

    if params[:status].present?
      @trackings = @trackings.where(delivery_status: params[:status])
    end

    @scheduled_tracking_ids = Sidekiq::ScheduledSet.new.map do |j|
      j.args.first if j.klass == 'RefreshTrackingStatus'
    end
  end

  # GET /trackings/1
  # GET /trackings/1.json
  def show
  end

  # GET /trackings/new
  def new
    @tracking = scopped_trackings.new
  end

  # GET /trackings/1/edit
  def edit
  end

  # POST /trackings
  # POST /trackings.json
  def create
    @tracking = scopped_trackings.new(tracking_params)

    respond_to do |format|
      if @tracking.save
        format.html do
          redirect_to(
            shop_trackings_url(params[:shop_id]),
            notice: 'Tracking was successfully created.'
          )
        end
        format.json { render :show, status: :created, location: @tracking }
      else
        format.html { render :new }
        format.json do
          render json: @tracking.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /trackings/1
  # PATCH/PUT /trackings/1.json
  def update
    respond_to do |format|
      if @tracking.update(tracking_params)
        format.html do
          redirect_to(
            shop_trackings_url(params[:shop_id]),
            notice: 'Tracking was successfully updated.'
          )
        end
        format.json { render :show, status: :ok, location: @tracking }
      else
        format.html { render :edit }
        format.json do
          render json: @tracking.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /trackings/1
  # DELETE /trackings/1.json
  def destroy
    @tracking.destroy
    respond_to do |format|
      format.html do
        redirect_to(
          shop_trackings_url(params[:shop_id]),
          notice: 'Tracking was successfully destroyed.'
        )
      end
      format.json { head :no_content }
    end
  end

  def refresh
    RefreshTrackingStatus.perform_async(params[:tracking_id])
    respond_to do |format|
      format.html do
        redirect_to(
          shop_trackings_url(params[:shop_id]),
          notice: 'Refresh Tracking scheduled.'
        )
      end
      format.json { head :no_content }
    end
  end

  private

  def tracking_params
    params.require(:tracking).permit(:code, :package, :carrier,
      :notification_url, :delivery_status, :tracker_url)
  end

  def set_tracking
    @tracking = scopped_trackings.find(params[:id])
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
