source 'https://rubygems.org'

ruby '2.4.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.0.1'
gem 'pg', '0.19.0'
gem 'puma', '~> 3.0'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails', '4.3.1'
gem 'faraday', '0.11.0'
gem 'faraday_middleware', '0.11.0.1'
gem 'nokogiri', '1.7.1'
gem 'httparty', '0.15.3'
gem 'jbuilder', '~> 2.5'
gem 'therubyracer', platforms: :ruby
source 'https://rails-assets.org' do
  gem 'rails-assets-sweetalert'
end
gem 'sidekiq', '4.2.9'
gem 'sinatra', require: nil
gem 'excon', '0.55.0'
gem 'savon', '2.11.1'
gem 'honeybadger', '~> 3.1'

group :development, :test do
  gem 'byebug', platform: :mri
end
