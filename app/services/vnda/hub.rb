# frozen_string_literal: true

module Vnda
  class Hub
    Error = Class.new(StandardError)
    HubResponseError = Class.new(Error)

    HUB_TOKEN = ENV['HUB_TOKEN']
    HUB_SCHEME = ENV['HUB_SCHEME']
    HUB_HOST = ENV['HUB_HOST']

    def initialize(host)
      @host = host
      @base_url = "#{HUB_SCHEME}://#{HUB_HOST}/api"
    end

    def get(endpoint)
      response = Excon.get("#{@base_url}/#{endpoint}",
        headers: headers,
        expects: 200)
      JSON.parse(response.body)
    rescue Excon::Errors::HTTPStatusError => ex
      return {} if ex.response.status == 404

      raise HubResponseError, ex.response.body
    rescue Excon::Error, JSON::ParserError => ex
      raise HubResponseError, ex.message
    end

    private

    def headers
      @headers ||= {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Token token=\"#{HUB_TOKEN}\"",
        'X-Host' => @host,
        'User-Agent' => 'tracker/' \
          "#{ENV.fetch('HEROKU_RELEASE_VERSION', 'dev')}"
      }
    end
  end
end
