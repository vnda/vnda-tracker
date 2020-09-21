# frozen_string_literal: true

module Vnda
  class Api
    API_SCHEME = ENV['API_SCHEME']
    API_TOKEN = ENV['API_TOKEN']

    def initialize(host)
      @host = host
      @base_url = "#{API_SCHEME}://#{@host}/api/v2"
    end

    def get(endpoint, query = {})
      connection(endpoint).get(query: query, expects: 200)
    end

    def post(endpoint, options)
      connection(endpoint).post(options)
    end

    private

    def connection(endpoint)
      Excon.new("#{@base_url}#{endpoint}", headers: headers)
    end

    def headers
      @headers ||= {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Token token=\"#{API_TOKEN}\"",
        'Host' => @host,
        'User-Agent' => 'vnda-tracker/' \
          "#{ENV.fetch('HEROKU_RELEASE_VERSION', 'dev')}"
      }
    end
  end
end
