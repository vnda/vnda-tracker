# frozen_string_literal: true

require 'rails_helper'

describe Intelipost do
  subject(:service) { described_class.new(shop) }

  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      notification_url: 'http://shop1.vnda.com.br',
      intelipost_api_key: 'foo'
    )
  end

  let(:headers) do
    {
      'Accept' => '*/*',
      'Api-Key' => 'foo',
      'Content-Type' => 'application/json'
    }
  end

  describe '#status' do
    context 'with events' do
      subject(:status) { service.status('OF526553827BR') }

      before do
        stub_request(:get, 'https://api.intelipost.com.br/api/v1/shipment_order/OF526553827BR')
          .with(headers: headers)
          .to_return(
            status: 200,
            body: {
              status: 'OK',
              content: {
                shipment_order_volume_array: [
                  delivered_date: '27/08/2018 12:43',
                  shipment_order_volume_state_localized: 'Entregue'
                ]
              }
            }.to_json
          )
      end

      it do
        expect(status).to eq(
          date: '27/08/2018 12:43 -0300'.to_datetime,
          status: 'delivered'
        )
      end
    end

    context 'when response does not have events' do
      subject(:status) { service.status('OF526553827BR') }

      before do
        stub_request(:get, 'https://api.intelipost.com.br/api/v1/shipment_order/OF526553827BR')
          .with(headers: headers)
          .to_return(
            status: 200,
            body: { status: 'ERR' }.to_json
          )
      end

      it { is_expected.to eq(date: nil, status: 'pending') }
    end

    context 'with an Excon error' do
      subject(:status) { service.status('OF526553827BR') }

      before do
        stub_request(
          :get,
          'https://api.intelipost.com.br/api/v1/shipment_order/OF526553827BR'
        ).to_return(status: 500)
      end

      it { is_expected.to eq(date: nil, status: 'pending') }
    end
  end

  describe '#events' do
    context 'with events' do
      subject(:events) { service.events('OF526553827BR') }

      before do
        stub_request(:get, 'https://api.intelipost.com.br/api/v1/shipment_order/OF526553827BR')
          .with(headers: headers)
          .to_return(
            status: 200,
            body: {
              status: 'OK',
              content: {
                shipment_order_volume_array: [
                  delivered_date: '27/08/2018 12:43',
                  shipment_order_volume_state_localized: 'Entregue'
                ]
              }
            }.to_json
          )
      end

      it do
        expect(events).to eq(
          [
            {
              date: '27/08/2018 12:43 -0300'.to_datetime,
              status: 'delivered'
            }
          ]
        )
      end
    end
  end

  describe '#parse_status' do
    statuses = {
      'Criado' => 'pending',
      'Pronto para envio' => 'pending',
      'Despachado' => 'in_transit',
      'Em trânsito' => 'in_transit',
      'Saiu para Entrega' => 'out_of_delivery',
      'Entregue' => 'delivered',
      'Cancelado' => 'expired'
    }

    statuses.each do |intelipost_status, app_status|
      it 'returns parsed status' do
        expect(service.parse_status(intelipost_status)).to eq(app_status)
      end
    end

    context 'with unexpected status' do
      it 'returns "exception" status' do
        expect(service.parse_status('foo')).to eq('exception')
      end
    end
  end
end
