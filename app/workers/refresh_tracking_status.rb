class RefreshTrackingStatus
  include Sidekiq::Worker

  def perform(tracking_id)
    tracking = Tracking.find(tracking_id)
    if tracking.update_status!
      notify_changes(tracking)
    else
      schedule_next_checking(tracking)
    end
  end

  protected

  def schedule_next_checking(tracking)
    RefreshTrackingStatus.perform_at(24.hours.from_now, tracking.id)
  end

  def notify_changes(tracking)
    if ["delivered"].include?(tracking.delivery_status)
      Notify.perform_async(tracking.id)
      retention_days = ENV["TRACKING_CODE_RETENTION_DAYS"].to_i
      DeleteTracking.perform_at(retention_days.days.from_now, tracking.id) if retention_days > 0
    elsif ["out_of_delivery", "failed_attempt"].include?(tracking.delivery_status)
      #send email
      schedule_next_checking(tracking)
    elsif tracking.delivery_status == "expired"
      #do nothing
    else
      schedule_next_checking(tracking)
    end
  end
end


