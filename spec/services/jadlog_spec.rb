# frozen_string_literal: true

require 'rails_helper'

describe Jadlog do
  subject(:jadlog) { described_class.new(shop) }

  let(:url) { 'https://www.jadlog.com.br/embarcador/api/tracking/consultar' }
  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      notification_url: 'http://shop1.vnda.com.br',
      jadlog_password: 'foo'
    )
  end

  let(:response_with_error) do
    {
      'consulta': [
        {
          'cte': '1800000000000',
          'error': { 'id': -1, 'descricao': 'Nao localizado.' }
        }
      ]
    }
  end

  let(:response_with_event) do
    {
      'consulta': [
        {
          'cte': '1800000000002',
          'tracking': {
            'codigo': '1800000000002',
            'shipmentId': '00000000000000',
            'dacte': '000000000000000000000000000000000000000000000',
            'dtEmissao': '19/04/2018',
            'status': 'EMISSAO',
            'valor': 32.75,
            'peso': 20,
            'eventos': [
              {
                'data': '2018-04-19 20:33:39',
                'status': 'EMISSAO',
                'unidade': 'JADLOG SEDE'
              }
            ]
          }
        }
      ]
    }
  end

  let(:response_without_event) do
    {
      'consulta': [
        {
          'cte': '1800000000002',
          'tracking': {
            'codigo': '1800000000002',
            'shipmentId': '00000000000000',
            'dacte': '000000000000000000000000000000000000000000000',
            'dtEmissao': '19/04/2018',
            'status': 'EMISSAO',
            'valor': 32.75,
            'peso': 20,
            'eventos': []
          }
        }
      ]
    }
  end

  describe '#status' do
    it 'returns tracking code status' do
      stub_request(:post, url)
        .with(
          body: { 'consulta' => [{ 'shipmentId' => '1800000000002' }] }.to_json,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)

      expect(jadlog.status('1800000000002')).to eq(
        date: '2018-04-19 20:33:39 -0300'.to_datetime,
        status: 'in_transit',
        message: 'EMISSAO'
      )
    end

    it 'returns pending when does not have events' do
      stub_request(:post, url)
        .with(
          body: { 'consulta' => [{ 'shipmentId' => '1800000000002' }] }.to_json,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_error.to_json)

      expect(jadlog.status('1800000000002')).to eq(
        date: nil,
        status: 'pending',
        message: nil
      )
    end

    it 'returns pending with empty response' do
      stub_request(:post, url)
        .with(
          body: { 'consulta' => [{ 'shipmentId' => '1800000000002' }] }.to_json,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: {}.to_json)

      expect(jadlog.status('1800000000002')).to eq(
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
          body: { 'consulta' => [{ 'shipmentId' => '1800000000002' }] }.to_json,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)
    end

    it do
      expect(jadlog.events('1800000000002')).to eq(
        [
          {
            date: '2018-04-19 20:33:39 -0300'.to_datetime,
            status: 'in_transit',
            message: 'EMISSAO'
          }
        ]
      )
    end
  end

  describe '#last_response' do
    before do
      stub_request(:post, url)
        .with(
          body: { 'consulta' => [{ 'shipmentId' => '1800000000002' }] }.to_json,
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: response_with_event.to_json)

      jadlog.events('1800000000002')
    end

    it 'returns the integration response' do
      expect(jadlog.last_response).to eq(response_with_event.to_json)
    end
  end

  describe '#parse_status' do
    statuses = {
      'EMISSAO' => 'in_transit',
      'ENTRADA' => 'in_transit',
      'TRANSFERENCIA' => 'in_transit',
      'EM ROTA' => 'out_of_delivery',
      'ENTREGUE' => 'delivered'
    }.freeze

    statuses.each do |jadlog_status, app_status|
      it 'returns parsed status' do
        expect(jadlog.parse_status(jadlog_status)).to eq(app_status)
      end
    end

    context 'with unexpected status' do
      it 'returns "exception" status' do
        expect(jadlog.parse_status('foo')).to eq('exception')
      end
    end
  end
end
