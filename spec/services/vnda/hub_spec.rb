# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vnda::Hub do
  subject(:hub) { described_class.new('demo.vnda.com.br') }

  describe '#get' do
    subject(:result) { hub.get(endpoint) }

    let(:endpoint) { 'endpoint1' }
    let(:response_body) { { 'result' => 'Api response' }.to_json }

    before do
      stub_const("#{described_class}::HUB_SCHEME", 'https')
      stub_const("#{described_class}::HUB_HOST", 'hub.vnda.com.br')
      stub_const("#{described_class}::HUB_TOKEN", 'hub_token')

      stub_request(:get, 'https://hub.vnda.com.br/api/endpoint1')
        .with(
          headers:
          {
            'Accept' => 'application/json',
            'Authorization' => 'Token token="hub_token"',
            'Content-Type' => 'application/json',
            'X-Host' => 'demo.vnda.com.br',
            'User-Agent' => 'tracker/dev'
          }
        )
        .to_return(status: 200, body: response_body)
    end

    context 'with JSON response' do
      it 'returns the request response' do
        expect(result).to eq('result' => 'Api response')
      end
    end

    context 'with string response' do
      let(:response_body) { 'Api response' }

      it 'raises error' do
        expect { result }.to raise_error(
          Vnda::Hub::HubResponseError,
          "765: unexpected token at 'Api response'"
        )
      end
    end

    context 'when not found' do
      before do
        stub_request(:get, 'https://hub.vnda.com.br/api/endpoint1')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'Authorization' => 'Token token="hub_token"',
              'Content-Type' => 'application/json',
              'X-Host' => 'demo.vnda.com.br',
              'User-Agent' => 'tracker/dev'
            }
          )
          .to_return(status: 404)
      end

      it 'returns empty hash' do
        expect(result).to eq({})
      end
    end

    context 'with HTTP Status error' do
      before do
        stub_request(:get, 'https://hub.vnda.com.br/api/endpoint1')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'Authorization' => 'Token token="hub_token"',
              'Content-Type' => 'application/json',
              'X-Host' => 'demo.vnda.com.br',
              'User-Agent' => 'tracker/dev'
            }
          )
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises error' do
        expect { result }.to raise_error(
          Vnda::Hub::HubResponseError,
          'Internal Server Error'
        )
      end
    end

    context 'with generic Excon error' do
      before do
        stub_request(:get, 'https://hub.vnda.com.br/api/endpoint1')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'Authorization' => 'Token token="hub_token"',
              'Content-Type' => 'application/json',
              'X-Host' => 'demo.vnda.com.br',
              'User-Agent' => 'tracker/dev'
            }
          )
          .to_raise(Excon::Error.new('Generic error message'))
      end

      it 'raises error' do
        expect { result }.to raise_error(
          Vnda::Hub::HubResponseError,
          'Generic error message'
        )
      end
    end
  end
end
