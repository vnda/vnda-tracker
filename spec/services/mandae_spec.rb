# frozen_string_literal: true

require 'rails_helper'

describe Mandae do
  subject(:mandae) { described_class.new(shop) }

  let(:url) { 'https://api.mandae.com.br/v2/trackings/134763521' }

  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      notification_url: 'http://shop1.vnda.com.br',
      mandae_token: 'foo'
    )
  end

  let(:response_with_error) do
    {
      'error' => {
        'message' => '134763521 not found',
        'code' => '404'
      }
    }
  end

  let(:response_with_event) do
    {
      'idItemParceiro' => nil,
      'trackingCode' => '133440397',
      'partnerItemId' => nil,
      'carrierName' => 'OnTime',
      'carrierCode' => '3130187',
      'events' => [
        {
          'timestamp' => '2019-03-23T17:28:02',
          'description' => 'A entrega foi realizada',
          'name' => 'Entrega realizada',
          'date' => '2019-03-23 17:28',
          'id' => '1'
        },
        {
          'id' => nil,
          'timestamp' => '2019-02-25T14:53:50',
          'description' => 'Sua encomenda está em processo de separação.',
          'name' => 'Encomenda coletada',
          'date' => '2019-02-25 14:53'
        }
      ]
    }
  end

  let(:response_without_event) do
    {
      'idItemParceiro' => nil,
      'trackingCode' => '133440397',
      'partnerItemId' => nil,
      'carrierName' => 'OnTime',
      'carrierCode' => '3130187',
      'events' => []
    }
  end

  describe '#status' do
    it 'returns tracking code status' do
      stub_request(:get, url)
        .with(
          headers: {
            'Authorization' => 'foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)

      expect(mandae.status('134763521')).to eq(
        date: '2019-03-23 17:28 -0300'.to_datetime,
        status: 'delivered',
        message: 'A entrega foi realizada'
      )
    end

    it 'returns pending when does not have events' do
      stub_request(:get, url)
        .with(
          headers: {
            'Authorization' => 'foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_error.to_json)

      expect(mandae.status('134763521')).to eq(
        date: nil,
        status: 'pending',
        message: nil
      )
    end
  end

  describe '#parse_status' do
    statuses = {
      'Encomenda coletada' => 'in_transit',
      'Recebida na Mandaê' => 'in_transit',
      'Encomenda encaminhada' => 'in_transit',
      'Processo iniciado pela transportadora' => 'in_transit',
      'Processada na unidade da transportadora' => 'in_transit',
      'Recebida na unidade da transportadora' => 'in_transit',
      'Rota final' => 'in_transit',
      'Redespachado pelos Correios' => 'in_transit',
      'Disponível para retirada na unidade da transportadora' =>
        'out_of_delivery',
      'Nova entrega agendada' => 'out_of_delivery',
      'Destinatário ausente' => 'out_of_delivery',
      'Pedido entregue' => 'delivered',
      'Entrega realizada' => 'delivered'
    }.freeze

    statuses.each do |mandae_status, app_status|
      it 'returns parsed status' do
        expect(mandae.parse_status(mandae_status)).to eq(app_status)
      end
    end

    context 'with unexpected status' do
      it 'returns "exception" status' do
        expect(mandae.parse_status('foo')).to eq('exception')
      end
    end
  end
end
