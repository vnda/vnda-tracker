# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails' do
  add_group 'Enumerations', 'app/enumerations'
  add_group 'Services', 'app/services'
  add_group 'Workers', 'app/workers'
  add_filter '.gems'
  add_filter 'vendor'
end

if ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
