# frozen_string_literal: true

namespace :tracker do
  desc 'Extract host by notification_url field and fill shop host column'
  task fill_shop_host_by_notification_url: :environment do
    Shop.where(host: nil).each do |shop|
      next if shop.notification_url.blank?

      begin
        host = URI(shop.notification_url).host
      rescue URI::InvalidURIError
        puts "Parser error(url): #{shop.notification_url}"
        next
      end

      shop.host = host
      shop.save
    end
  end
end
