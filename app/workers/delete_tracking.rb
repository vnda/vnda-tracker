class DeleteTracking
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(tracking_id)
    Tracking.find(tracking_id).delete
  end
end
