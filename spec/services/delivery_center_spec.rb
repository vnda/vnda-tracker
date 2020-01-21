# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeliveryCenter do
  subject(:delivery_center) { described_class.new(shop) }

  let(:url) { 'https://api.deliverycenter.com/oms/v1/order/S5A48' }

  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      notification_url: 'http://shop1.vnda.com.br',
      delivery_center_enabled: true,
      delivery_center_token: 'foo'
    )
  end

  let(:response_with_error) { nil }

  let(:response_with_event) do
    {
      'id' => 1,
      'code' => '14s5a2d',
      'externalCode' => '41546156rfe4156rf1e4wdrew5',
      'trackingCode' => 'S5A48',
      'sellerChannelCode' => 11,
      'observation' => 'Alguma observação',
      'subTotal' => 5,
      'deliveryFee' => 10,
      'total' => 15,
      'signalizedPaymentType' => 'PAY',
      'signalizedPaymentChargeValue' => 15,
      'country' => 'BR',
      'state' => 'AC',
      'city' => 'BUJARI',
      'district' => 'OUTROS',
      'street' => 'R TESTE',
      'number' => '100',
      'postalCode' => '12345678',
      'complement' => nil,
      'latitude' => -9.824359,
      'longitude' => -67.950572,
      'dtOrderCreate' => '2018-02-14T22:38:09.912Z',
      'dtStatusUpdate' => '2018-02-14T22:38:09.912Z',
      'dtOrderDelivered' => '2018-02-14T22:38:09.912Z',
      'dtEta' => '2018-02-14T22:38:09.912Z',
      'routeDistance' => 1500,
      'customer' => {
        'externalCode' => '1213123',
        'name' => 'DeliveryCenter Cliente',
        'contact' => '19984056984',
        'email' => 'deliveryCenter@deliveryCenter.com'
      },
      'items' => [
        {
          'externalCode' => '1',
          'name' => 'Refrigerante',
          'price' => 5,
          'quantity' => 1,
          'total' => 5.00,
          'observation' => 'sem gelo',
          'subItems' => [
            {
              'externalCode' => '14',
              'name' => 'Coca-cola',
              'observation' => 'sem gelo',
              'price' => 0.00,
              'quantity' => '1',
              'total' => 0.00
            }
          ]
        }
      ],
      'payments' => [
        {
          'type' => 'PAY',
          'value' => 15.00
        }
      ]
    }
  end

  describe '#status' do
    it 'returns tracking code status' do
      stub_request(:get, url)
        .with(
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)

      expect(delivery_center.status('S5A48')).to eq(
        date: '2018-02-14T22:38:09.912Z'.to_time,
        status: 'delivered',
        message: '1500 metros restantes'
      )
    end

    it 'returns pending when does not have events' do
      stub_request(:get, url)
        .with(
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_error.to_json)

      expect(delivery_center.status('S5A48')).to eq(
        date: nil,
        status: 'pending',
        message: nil
      )
    end
  end

  describe '#last_response' do
    it 'returns last response' do
      stub_request(:get, url)
        .with(
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)

      delivery_center.status('S5A48')

      expect(delivery_center.last_response).to eq(response_with_event.to_json)
    end
  end

  describe '#events' do
    it 'returns a empty array' do
      stub_request(:get, url)
        .with(
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)

      expect(delivery_center.events('S5A48')).to eq([])
    end
  end

  describe '#parse_status' do
    context 'without delivery date' do
      let(:event) { { 'dtOrderDelivered' => nil } }

      it 'returns parsed status' do
        expect(delivery_center.parse_status(event)).to eq('in_transit')
      end
    end

    context 'with delivery date' do
      let(:event) { { 'dtOrderDelivered' => '2018-02-14T22:38:09.912Z' } }

      it 'returns parsed status' do
        expect(delivery_center.parse_status(event)).to eq('delivered')
      end
    end
  end
end
