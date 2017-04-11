source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


gem 'rails', '~> 5.0.1'
gem 'pg'
gem 'puma', '~> 3.0'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'faraday'
gem 'faraday_middleware'
gem 'nokogiri'
gem 'jbuilder', '~> 2.5'
gem 'therubyracer', platforms: :ruby
source 'https://rails-assets.org' do
  gem 'rails-assets-sweetalert'
end
gem 'sidekiq'
gem 'sinatra', require: nil
gem 'excon'
gem 'savon'

group :development, :test do
  gem 'byebug', platform: :mri
end
