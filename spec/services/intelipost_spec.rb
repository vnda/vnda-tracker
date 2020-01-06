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
                  modified_iso: '2019-12-26T16:41:12.495-03:00',
                  delivered_date: 1_577_365_620_000,
                  delivered_date_iso: '2019-12-26T10:07:00.000-03:00',
                  shipment_order_volume_state_localized: 'Entregue'
                ]
              }
            }.to_json
          )
      end

      it do
        expect(status).to eq(
          date: '26/12/2019 10:07 -0300'.to_datetime,
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
                  modified_iso: '2019-12-26T16:41:12.495-03:00',
                  delivered_date: 1_577_365_620_000,
                  delivered_date_iso: '2019-12-26T10:07:00.000-03:00',
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
              date: '26/12/2019 10:07 -0300'.to_datetime,
              status: 'delivered'
            }
          ]
        )
      end
    end
  end

  describe '#last_response' do
    subject(:last_response) { service.last_response }

    let(:response_body) do
      {
        status: 'OK',
        content: {
          shipment_order_volume_array: [
            delivered_date: 1_577_365_620_000,
            delivered_date_iso: '2019-12-26T10:07:00.000-03:00',
            shipment_order_volume_state_localized: 'Entregue'
          ]
        }
      }.to_json
    end

    before do
      stub_request(:get, 'https://api.intelipost.com.br/api/v1/shipment_order/OF526553827BR')
        .with(headers: headers)
        .to_return(
          status: 200,
          body: response_body
        )

      service.status('OF526553827BR')
    end

    it 'returns the integration response' do
      expect(last_response).to eq(response_body)
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
