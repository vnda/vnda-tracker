# frozen_string_literal: true

require 'rails_helper'

describe Loggi do
  subject(:loggi) { described_class.new(shop) }

  let(:url) { 'https://staging.loggi.com/graphql' }

  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      host: 'shop1.vnda.com.br',
      loggi_enabled: true,
      loggi_token: '123',
      loggi_email: 'ajuda@vnda.com.br',
      loggi_shop_id: '2',
      loggi_api_url: 'https://staging.loggi.com/graphql',
      loggi_pattern: '^(\(?\+?[0-9]*\)?)?[0-9_\- \(\)]*$'
    )
  end

  let(:response_with_error) do
    {
      'errors' => [
        {
          'message' => 'Error'
        }
      ]
    }.to_json
  end

  let(:response_with_success) do
    {
      'data' => {
        'retrieveOrderWithPk' => {
          'status' => 'allocating',
          'statusDisplay' => 'Em alocação',
          'originalEta' => 158_522_508_0
        }
      }
    }.to_json
  end

  let(:body) do
    tracking_code = 123_456
    {
      'query' => "query {
        retrieveOrderWithPk(orderPk: #{tracking_code}) {
          status
          statusDisplay
          originalEta
        }
      }"
    }
  end

  describe '#status' do
    it 'returns tracking code status' do
      stub_request(:post, 'https://staging.loggi.com/graphql')
        .with(
          body: body,
          headers: {
            'Authorization' => 'ApiKey ajuda@vnda.com.br:123',
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 200, body: response_with_success)

      expect(loggi.status('123456')).to eq(
        date: '2020-03-26 09:18 -0300'.to_datetime,
        status: 'in_transit',
        message: 'Em alocação'
      )
    end

    it 'returns pending when does not have events' do
      stub_request(:post, 'https://staging.loggi.com/graphql')
        .with(
          body: body,
          headers: {
            'Authorization' => 'ApiKey ajuda@vnda.com.br:123',
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 200, body: response_with_error)

      expect(loggi.status('123456')).to eq(
        date: nil,
        status: 'pending',
        message: nil
      )
    end
  end

  describe '#events' do
    it 'returns tracking code status' do
      stub_request(:post, 'https://staging.loggi.com/graphql')
        .with(
          body: body,
          headers: {
            'Authorization' => 'ApiKey ajuda@vnda.com.br:123',
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 200, body: response_with_success)

      expect(loggi.events('123456').first).to eq(
        date: '2020-03-26 09:18 -0300'.to_datetime,
        status: 'in_transit',
        message: 'Em alocação'
      )
    end

    it 'returns pending when does not have events' do
      stub_request(:post, 'https://staging.loggi.com/graphql')
        .with(
          body: body,
          headers: {
            'Authorization' => 'ApiKey ajuda@vnda.com.br:123',
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 200, body: response_with_error)

      expect(loggi.events('123456').first).to eq(
        date: nil,
        status: 'pending',
        message: nil
      )
    end
  end

  describe '#validate_tracking_code' do
    context 'without shop' do
      it 'returns false' do
        expect(
          described_class.validate_tracking_code(nil, '123456')
        ).to be_falsey
      end
    end

    context 'without loggi enabled' do
      it 'returns false' do
        shop.loggi_enabled = false
        expect(
          described_class.validate_tracking_code(shop, '123456')
        ).to be_falsey
      end
    end

    context 'without loggi pattern' do
      it 'returns false' do
        shop.loggi_pattern = nil
        expect(
          described_class.validate_tracking_code(shop, '123456')
        ).to be_falsey
      end
    end

    context 'when regex pattern does not match' do
      it 'returns false' do
        expect(
          described_class.validate_tracking_code(shop, '123456abc')
        ).to be_falsey
      end
    end

    context 'when regex pattern does match' do
      it 'returns true' do
        expect(
          described_class.validate_tracking_code(shop, '123456')
        ).to be_truthy
      end
    end
  end

  describe '#parse_status' do
    statuses = {
      'allocating' => 'in_transit',
      'accepted' => 'in_transit',
      'dropped' => 'in_transit',
      'started' => 'out_of_delivery',
      'finished' => 'delivered'
    }.freeze

    statuses.each do |loggi_status, app_status|
      it 'returns parsed status' do
        expect(loggi.parse_status(loggi_status)).to eq(app_status)
      end
    end

    context 'with unexpected status' do
      it 'returns "exception" status' do
        expect(loggi.parse_status('foo')).to eq('exception')
      end
    end
  end
end
