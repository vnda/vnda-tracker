# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.5.3'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails', '4.3.1'
gem 'sass-rails', '~> 5.0'
gem 'therubyracer', platforms: :ruby
gem 'uglifier', '>= 1.3.0'
source 'https://rails-assets.org' do
  gem 'rails-assets-sweetalert'
end

gem 'bootsnap', require: false
gem 'excon', '0.71.0'
gem 'faraday', '0.15.4'
gem 'faraday_middleware', '0.13.1'
gem 'honeybadger', '3.3.1'
gem 'nokogiri', '1.10.4'
gem 'pg', '0.21.0'
gem 'puma', '3.12.2'
gem 'rails', '5.2.4.1'
gem 'savon', '2.12.0'
gem 'sidekiq', '4.2.10'
gem 'sinatra', require: nil

group :development, :test do
  gem 'byebug'
  gem 'faker'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec-rails', '3.8.2'
  gem 'rspec_junit_formatter', '0.4.1'
  gem 'rubocop', '~> 0.65.0', require: false
  gem 'rubocop-rspec', '1.32.0'
end

group :test do
  gem 'codecov', '0.1.14', require: false
  gem 'simplecov', '0.16.1', require: false
  gem 'timecop', '0.9.1'
  gem 'webmock', require: 'webmock/rspec'
end
