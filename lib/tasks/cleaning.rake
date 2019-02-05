# frozen_string_literal: true

namespace :cleaning do
  desc 'Removes old trackings'
  task old_trackings: :environment do
    retention_days = ENV['TRACKING_CODE_RETENTION_DAYS'].to_i
    exit if retention_days.zero?

    codes = Tracking
      .where("delivery_status in ('delivered', 'expired')")
      .where('updated_at < ?', retention_days.days.ago)

    puts "Removing #{codes.count} delivered or expired trackings"
    codes.destroy_all

    codes = Tracking.where('updated_at < ?', (retention_days * 2).days.ago)

    puts "Removing #{codes.count} dead trackings"
    codes.destroy_all
  end
end
