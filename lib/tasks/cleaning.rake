# frozen_string_literal: true

namespace :cleaning do
  desc 'Removes old trackings'
  task old_trackings: :environment do
    retention_days = ENV['TRACKING_CODE_RETENTION_DAYS']
    exit unless retention_days

    codes = Tracking
      .where("delivery_status in ('delivered', 'expired')")
      .where('updated_at < ?', retention_days.to_i.days.ago)

    puts "Removing #{codes.count} old trackings"
    codes.destroy_all
  end
end
