# frozen_string_literal: true

require 'rails_helper'

describe 'Intelipost', type: :request do
  subject(:response_content) { response.body }

  let(:shop) do
    Shop.create!(
      name: 'foo',
      token: 'a1b2c3d4e5',
      intelipost_id: 'abc',
      intelipost_api_key: '12345',
      host: 'shop1.vnda.com.br'
    )
  end

  describe 'POST /intelipost/receive_hook' do
    before do
      post(
        '/intelipost/receive_hook',
        params: { tracking_code: 'A1B2C3D4E5', order_number: 'A1B2C3D4E5-01' },
        headers: { 'api-key' => shop.intelipost_api_key }
      )
    end

    it { expect(response.status).to eq(204) }
    it { expect(Tracking.last.code).to eq('A1B2C3D4E5') }
    it { expect(Tracking.last.carrier).to eq('intelipost') }
    it { expect(Tracking.last.package).to eq('A1B2C3D4E5-01') }
    it do
      expect(Tracking.last.tracker_url).to eq(
        'https://status.ondeestameupedido.com/tracking/abc/A1B2C3D4E5-01'
      )
    end
  end
end
