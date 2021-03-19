# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.release = ENV['APP_REVISION'] || 'dev'
  config.enabled_environments = %w[development staging production]
  config.environment = ENV['SENTRY_ENV'] || 'development'
end
