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
  rescue ActiveRecord::RecordNotFound
    logger.error("Tracking #{tracking_id} not found")
  rescue Carrier::UnsupportedCarrierError
    logger.error("Tracking #{tracking.attributes} have an unsupported carrier")
  end

  protected

  def schedule_next_checking(tracking, interval = 24)
    RefreshTrackingStatus.perform_at(interval.hours.from_now, tracking.id)
  end

  def notify_changes(tracking)
    if tracking.delivery_status == 'in_transit'
      Notify.perform_async(tracking.id)
      schedule_next_checking(tracking)
    elsif tracking.delivery_status == 'delivered'
      Notify.perform_async(tracking.id)
    elsif tracking.delivery_status == 'out_of_delivery'
      Notify.perform_async(tracking.id)
      schedule_next_checking(tracking, 6)
    elsif %w[failed_attempt].include?(tracking.delivery_status)
      # send email
      schedule_next_checking(tracking, 6)
    elsif tracking.delivery_status == 'expired'
      # do nothing
    else
      schedule_next_checking(tracking)
    end
  end
end
