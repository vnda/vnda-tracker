# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MelhorEnvio do
  subject(:melhor_envio) { described_class.new(shop) }

  let(:url) { 'https://sandbox.melhorenvio.com.br/api/v2/me/shipment/tracking' }

  let(:params) do
    { 'orders' => ['6e1c864a-fe48-4ae7-baaa-d6e4888bafd1'] }.to_json
  end

  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      host: 'shop1.vnda.com.br',
      melhor_envio_enabled: true,
      melhor_envio_environment: melhor_envio_environment
    )
  end

  let(:melhor_envio_environment) { 'sandbox' }

  let(:response_with_error) do
    {
      'message' => 'The given data was invalid.',
      'errors' => { 'orders.0' => ['O campo deve ter 36 caracteres.'] }
    }
  end

  let(:response_with_event) do
    {
      '6e1c864a-fe48-4ae7-baaa-d6e4888bafd1' => {
        'status' => 'delivered',
        'tracking' => 'PP123456789BR',
        'melhorenvio_tracking' => 'ME123456789BR',
        'created_at' => '2020-06-06 15:50:55',
        'paid_at' => '2020-06-06 16:50:55',
        'generated_at' => '2020-06-06 17:50:55',
        'posted_at' => '2020-06-06 18:50:55',
        'delivered_at' => '2020-06-07 15:50:55',
        'canceled_at' => '',
        'expired_at' => ''
      }
    }
  end

  let(:response_without_event) { [] }

  before do
    stub_request(:get, 'http://shop1.vnda.com.br/api/v2/shop')
      .to_return(
        status: 200,
        body: {
          settings: {
            melhor_envio_access_token: 'foo'
          }
        }.to_json
      )
  end

  describe '#status' do
    it 'returns tracking code status' do
      stub_request(:post, url)
        .with(
          body: params,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)

      expect(melhor_envio.status('6e1c864a-fe48-4ae7-baaa-d6e4888bafd1')).to eq(
        date: '2020-06-07 15:50:55'.to_datetime,
        status: 'delivered',
        message: nil
      )
    end

    it 'returns pending when does not have events' do
      stub_request(:post, url)
        .with(
          body: params,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_error.to_json)

      expect(melhor_envio.status('6e1c864a-fe48-4ae7-baaa-d6e4888bafd1')).to eq(
        date: nil,
        status: 'pending',
        message: nil
      )
    end

    it 'returns pending when response is empty' do
      stub_request(:post, url)
        .with(
          body: params,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(status: 200, body: [].to_json)

      expect(melhor_envio.status('6e1c864a-fe48-4ae7-baaa-d6e4888bafd1')).to eq(
        date: nil,
        status: 'pending',
        message: nil
      )
    end

    it 'when raises returns pending' do
      stub_request(:post, url)
        .with(
          body: params,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        ).to_raise(Excon::Errors::Error)

      expect(melhor_envio.status('6e1c864a-fe48-4ae7-baaa-d6e4888bafd1')).to eq(
        date: nil,
        status: 'pending',
        message: nil
      )
    end
  end

  describe '#events' do
    before do
      stub_request(:post, url)
        .with(
          body: params,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)
    end

    it 'returns events' do
      expect(melhor_envio.events('6e1c864a-fe48-4ae7-baaa-d6e4888bafd1')).to eq(
        [
          {
            date: '2020-06-07 15:50:55'.to_datetime,
            status: 'delivered',
            message: nil
          }
        ]
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
        shop.melhor_envio_enabled = false
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
          described_class.validate_tracking_code(
            shop,
            '6e1c864a-fe48-4ae7-baaa-d6e4888bafd1'
          )
        ).to be_truthy
      end
    end
  end

  describe '#last_response' do
    let(:melhor_envio_environment) { 'production' }

    before do
      stub_request(:post, 'https://melhorenvio.com.br/api/v2/me/shipment/tracking')
        .with(
          body: params,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)

      melhor_envio.events('6e1c864a-fe48-4ae7-baaa-d6e4888bafd1')
    end

    it 'returns the integration response and used production host' do
      expect(melhor_envio.last_response).to eq(response_with_event.to_json)
    end
  end

  describe '#parse_status' do
    statuses = {
      'pending' => 'pending',
      'posted' => 'in_transit',
      'released' => 'in_transit',
      'delivered' => 'delivered'
    }.freeze

    statuses.each do |melhor_envio_status, app_status|
      it 'returns parsed status' do
        expect(melhor_envio.parse_status(melhor_envio_status)).to eq(app_status)
      end
    end

    context 'with unexpected status' do
      it 'returns "exception" status' do
        expect(melhor_envio.parse_status('foo')).to eq('exception')
      end
    end
  end
end
