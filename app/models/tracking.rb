class Tracking < ApplicationRecord
  STATUSES = [
    "pending",
    "in_transit",
    "out_of_delivery",
    "delivered",
    "failed_attempt",
    "expection",
    "expired"
  ]

  belongs_to :shop

  validates :code, presence: true, if: lambda{ |o| o.carrier != 'intelipost' }
  validates :delivery_status, presence: :true
  validates :code, uniqueness: { scope: [:shop_id, :carrier], allow_blank: true }

  before_validation :default_delivery_status, :discover_carrier, :discover_tracker_url
  after_commit :schedule_update, :forward_to_intelipost, on: [:create]

  def searchable
    return package if carrier == 'intelipost'

    code
  end

  def update_status!
    hash = Carrier.new(shop, carrier).status(searchable)

    if hash[:date].present?
      if 30.days.ago > hash[:date]
        self.delivery_status = "expired"
        save!
        return true
      end

      if last_checkpoint_at.nil? || last_checkpoint_at < hash[:date]
        self.delivery_status = hash[:status]
        self.last_checkpoint_at = hash[:date]
        save!
        return true
      end
    end

    false
  end

  def has_job?
    ss = Sidekiq::ScheduledSet.new
    job = ss.find do |e|
      [e["class"], e.args[0]] == ["RefreshTrackingStatus", self.id]
    end
    job.present?
  end

  private

  def forward_to_intelipost
    Intelipost.new(shop).update_tracking(package, code)
  end

  def schedule_update
    RefreshTrackingStatus.perform_at(24.hours.from_now, id)
  end

  def discover_carrier
    self.carrier ||= Carrier.discover(code)
  end

  def discover_tracker_url
    self.tracker_url ||= Carrier.url(carrier, searchable)
  end

  def default_delivery_status
    self.delivery_status ||= "pending"
  end
end
