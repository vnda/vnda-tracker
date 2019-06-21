# frozen_string_literal: true

class TrackingEvent < ApplicationRecord
  belongs_to :tracking

  validates :delivery_status, :tracking, presence: true

  def self.register(events, tracking)
    events.each do |event|
      find_or_create_by(
        checkpoint_at: event[:date],
        delivery_status: event[:status],
        message: event[:message],
        tracking_id: tracking.id
      )
    end
  end
end
