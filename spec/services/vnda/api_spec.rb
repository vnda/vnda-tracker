# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vnda::Api do
  subject(:api) { described_class.new('demo.vnda.com.br') }

  describe '#get' do
    subject(:result) { api.get(endpoint, query).body }

    let(:endpoint) { '/endpoint1' }
    let(:query) { { arg1: 'value1' } }

    before do
      stub_request(
        :get,
        'http://demo.vnda.com.br/api/v2/endpoint1?arg1=value1'
      ).with(
        headers:
        {
          'Accept' => 'application/json',
          'Authorization' => 'Token token="api_token"',
          'Content-Type' => 'application/json',
          'Host' => 'demo.vnda.com.br',
          'User-Agent' => 'vnda-tracker/dev'
        }
      ).to_return(status: 200, body: 'Api response')
    end

    it 'returns body response' do
      expect(result).to eq('Api response')
    end
  end

  describe '#post' do
    subject(:result) { api.post(endpoint, body: body.to_json).body }

    let(:endpoint) { '/endpoint1' }
    let(:body) { { arg1: 'value1' } }

    before do
      stub_request(
        :post,
        'http://demo.vnda.com.br/api/v2/endpoint1'
      ).with(
        headers:
        {
          'Accept' => 'application/json',
          'Authorization' => 'Token token="api_token"',
          'Content-Type' => 'application/json',
          'Host' => 'demo.vnda.com.br',
          'User-Agent' => 'vnda-tracker/dev'
        },
        body: { arg1: 'value1' }
      ).to_return(status: 200, body: 'Api response')
    end

    it 'returns body response' do
      expect(result).to eq('Api response')
    end
  end
end
