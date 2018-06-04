# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.4.3'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'coffee-rails', '~> 4.2'
gem 'faraday', '0.11.0'
gem 'faraday_middleware', '0.11.0.1'
gem 'httparty', '0.15.3'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails', '4.3.1'
gem 'nokogiri', '1.8.2'
gem 'pg', '0.21.0'
gem 'puma', '3.11.2'
gem 'rails', '5.1.5'
gem 'sass-rails', '~> 5.0'
gem 'therubyracer', platforms: :ruby
gem 'uglifier', '>= 1.3.0'
source 'https://rails-assets.org' do
  gem 'rails-assets-sweetalert'
end
gem 'excon', '0.60.0'
gem 'honeybadger', '3.3.0'
gem 'savon', '2.12.0'
gem 'sidekiq', '4.2.10'
gem 'sinatra', require: nil

group :development, :test do
  gem 'byebug'
  gem 'faker'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec-rails'
  gem 'rubocop', '~> 0.56.0', require: false
  gem 'rubocop-rspec'
end

group :test do
  gem 'timecop', '0.9.1'
  gem 'webmock', require: 'webmock/rspec'
end
