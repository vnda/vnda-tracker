# frozen_string_literal: true

class RefreshTrackingStatus
  include Sidekiq::Worker

  def perform(tracking_id)
    tracking = Tracking.find(tracking_id)
    if tracking.update_status!
      notify_changes(tracking)
    else
      schedule_next_checking(tracking)
    end
  rescue Carrier::UnsupportedCarrierError
    logger.info("Tracking #{tracking.attributes} have an unsupported carrier")
  end

  protected

  def schedule_next_checking(tracking)
    RefreshTrackingStatus.perform_at(24.hours.from_now, tracking.id)
  end

  def notify_changes(tracking)
    if tracking.delivery_status == 'in_transit'
      Notify.perform_async(tracking.id)
      schedule_next_checking(tracking)
    elsif tracking.delivery_status == 'delivered'
      Notify.perform_async(tracking.id)
    elsif %w[out_of_delivery failed_attempt].include?(tracking.delivery_status)
      # send email
      schedule_next_checking(tracking)
    elsif tracking.delivery_status == 'expired'
      # do nothing
    else
      schedule_next_checking(tracking)
    end
  end
end
