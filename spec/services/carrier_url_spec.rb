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
      notification_url: 'http://shop1.vnda.com.br',
      intelipost_api_key: 'foo'
    )
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
end
