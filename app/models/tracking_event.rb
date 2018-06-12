# frozen_string_literal: true

class TrackingEvent < ApplicationRecord
  belongs_to :tracking

  validates :delivery_status, :tracking, presence: true

  def self.register(status, date, message)
    create!(
      delivery_status: status,
      checkpoint_at: date,
      message: message
    )
  end
end
