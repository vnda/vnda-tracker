# frozen_string_literal: true

require 'rails_helper'

describe CarrierURL do
  subject(:url) do
    described_class.fetch(carrier: carrier, code: 'A1B2C3D4E5', shop: shop)
  end

  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      host: 'shop1.vnda.com.br',
      intelipost_api_key: 'foo',
      intelipost_id: '12345'
    )
  end

  context 'with Intelipost' do
    let(:carrier) { 'intelipost' }

    it do
      expect(url).to eq('https://status.ondeestameupedido.com/tracking/12345/A1B2C3D4E5')
    end
  end

  context 'with Mandaê' do
    let(:carrier) { 'mandae' }

    it do
      expect(url).to eq('https://rastreae.com.br/resultado/A1B2C3D4E5')
    end
  end

  context 'with Correios' do
    let(:carrier) { 'correios' }

    it do
      expect(url).to eq('https://track.aftership.com/brazil-correios/A1B2C3D4E5')
    end
  end

  context 'with TNT' do
    let(:carrier) { 'tnt' }

    it do
      expect(url).to eq(
        'http://app.tntbrasil.com.br/radar/public/localizacaoSimplificadaDeta' \
        'il/A1B2C3D4E5'
      )
    end
  end

  context 'with Jadlog' do
    let(:carrier) { 'jadlog' }

    it do
      expect(url).to eq(
        'http://www.jadlog.com.br/siteDpd/tracking.jad?cte=A1B2C3D4E5'
      )
    end
  end

  context 'with Melhor Envio' do
    let(:carrier) { 'melhorenvio' }

    it 'returns URL' do
      stub_request(:get, 'http://shop1.vnda.com.br/api/v2/shop')
        .to_return(
          status: 200,
          body: {
            settings: {
              melhor_envio_access_token: 'foo'
            }
          }.to_json
        )

      stub_request(:post, 'https://sandbox.melhorenvio.com.br/api/v2/me/shipment/tracking')
        .with(
          body: '{"orders":["A1B2C3D4E5"]}',
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: {
            'A1B2C3D4E5' => {
              'tracking' => 'ME123456789BR'
            }
          }.to_json
        )

      expect(url).to eq('https://melhorrastreio.com.br/rastreio/ME123456789BR')
    end

    it 'does not return URL without tracking code' do
      stub_request(:get, 'http://shop1.vnda.com.br/api/v2/shop')
        .to_return(
          status: 200,
          body: {
            settings: {
              melhor_envio_access_token: 'foo'
            }
          }.to_json
        )

      stub_request(:post, 'https://sandbox.melhorenvio.com.br/api/v2/me/shipment/tracking')
        .with(
          body: '{"orders":["A1B2C3D4E5"]}',
          headers: {
            'Authorization' => 'Bearer foo',
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          }
        )
        .to_return(
          status: 200,
          body: {
            'A1B2C3D4E5' => {
              'tracking' => ''
            }
          }.to_json
        )

      expect(url).to eq(nil)
    end
  end

  context 'with Bling' do
    let(:carrier) { 'bling' }
    let(:bling_service) { instance_double(Bling) }

    before do
      allow(Bling).to receive(:new).with(shop).and_return(bling_service)
    end

    it 'returns URL' do
      allow(bling_service).to receive(:tracking_url).with('A1B2C3D4E5')
        .and_return(
          'www2.correios.com.br/sistemas/rastreamento?objetos=A1B2C3D4E5'
        )

      expect(url).to eq(
        'www2.correios.com.br/sistemas/rastreamento?objetos=A1B2C3D4E5'
      )
    end

    it 'does not return URL when response is nil' do
      allow(bling_service).to receive(:tracking_url)
        .with('A1B2C3D4E5')
        .and_return(nil)

      expect(url).to eq(nil)
    end
  end
end
