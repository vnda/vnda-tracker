class TrackingsController < ApplicationController
  before_action :set_tracking, only: [:show, :edit, :update, :destroy]

  # GET /trackings
  # GET /trackings.json
  def index
    @trackings = scopped_trackings.order(created_at: :desc)
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
        format.html { redirect_to shop_trackings_url(params[:shop_id]), notice: 'Tracking was successfully created.' }
        format.json { render :show, status: :created, location: @tracking }
      else
        format.html { render :new }
        format.json { render json: @tracking.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trackings/1
  # PATCH/PUT /trackings/1.json
  def update
    respond_to do |format|
      if @tracking.update(tracking_params)
        format.html { redirect_to shop_trackings_url(params[:shop_id]), notice: 'Tracking was successfully updated.' }
        format.json { render :show, status: :ok, location: @tracking }
      else
        format.html { render :edit }
        format.json { render json: @tracking.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trackings/1
  # DELETE /trackings/1.json
  def destroy
    @tracking.destroy
    respond_to do |format|
      format.html { redirect_to shop_trackings_url(params[:shop_id]), notice: 'Tracking was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def tracking_params
      params.require(:tracking).permit(:code, :carrier, :notification_url, :delivery_status, :url)
    end

    def set_tracking
      @tracking = scopped_trackings.find(params[:id])
    end

    def scopped_trackings
      @trackings ||= Shop.find(params[:shop_id]).trackings
    end
end
