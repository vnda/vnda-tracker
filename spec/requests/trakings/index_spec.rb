# frozen_string_literal: true

require 'rails_helper'

describe 'Trackings', type: :request do
  subject(:response_content) { response.body }

  let(:shop) do
    Shop.create!(name: 'foo', token: 'a1b2c3d4e5', host: 'vnda.com.br')
  end

  before do
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return([])
  end

  describe 'GET /shops/:shop_id/trackings' do
    it 'returns a list without trackings' do
      get(
        "/shops/#{shop.id}/trackings",
        params: { token: shop.token }
      )

      expect(response_content).to include('Nenhum tracking cadastrado')
    end

    context 'with tracking' do
      before do
        Tracking.create(
          shop_id: shop.id, code: 'tracking-123', delivery_status: 'pending'
        )
        Tracking.create(
          shop_id: shop.id, code: 'tracking-456', delivery_status: 'in_transit'
        )
      end

      it 'returns a list of trackings' do
        get(
          "/shops/#{shop.id}/trackings",
          params: { token: shop.token }
        )

        expect(response_content).to include('tracking-123')
      end

      it 'returns only trackings with selected status' do
        get(
          "/shops/#{shop.id}/trackings?status=in_transit",
          params: { token: shop.token }
        )

        expect(response_content).not_to include('tracking-123')
      end
    end
  end
end
