# frozen_string_literal: true

class Tracking < ApplicationRecord
  STATUSES = %w[
    pending
    in_transit
    out_of_delivery
    delivered
    failed_attempt
    expection
    expired
  ].freeze

  belongs_to :shop
  has_many :events, class_name: 'TrackingEvent', dependent: :destroy
  has_many :notifications,
    class_name: 'TrackingNotification',
    dependent: :destroy

  validates :code, presence: true, if: ->(o) { o.carrier != 'intelipost' }
  validates :delivery_status, presence: :true
  validates :code, uniqueness: { scope: %i[shop_id carrier], allow_blank: true }

  before_validation :default_delivery_status, :discover_carrier,
    :discover_tracker_url
  after_commit :schedule_update, :forward_to_intelipost, on: [:create]

  def searchable
    return package if carrier == 'intelipost'

    code
  end

  def update_status!
    hash = Carrier.new(shop, carrier).status(searchable)

    if hash[:date].present?
      if 30.days.ago > hash[:date]
        self.delivery_status = 'expired'
      elsif last_checkpoint_at.nil? || last_checkpoint_at < hash[:date]
        self.delivery_status = hash[:status]
        self.last_checkpoint_at = hash[:date]
      end

      if changed?
        save!
        events.register(delivery_status, hash[:date], hash[:message])
        return true
      end
    end

    false
  end

  def has_job?
    ss = Sidekiq::ScheduledSet.new
    job = ss.find do |e|
      [e['class'], e.args[0]] == ['RefreshTrackingStatus', id]
    end
    job.present?
  end

  private

  def forward_to_intelipost
    return unless shop.forward_to_intelipost
    Intelipost.new(shop).update_tracking(package, code)
  end

  def schedule_update
    RefreshTrackingStatus.perform_at(24.hours.from_now, id)
  end

  def discover_carrier
    self.carrier ||= Carrier.discover(code, shop)
  end

  def discover_tracker_url
    self.tracker_url ||= Carrier.url(
      carrier: carrier,
      code: searchable,
      shop: shop
    )
  end

  def default_delivery_status
    self.delivery_status ||= 'pending'
  end
end
