# frozen_string_literal: true

require 'rails_helper'

describe 'Trackings', type: :request do
  subject(:response_content) { response.body }

  let(:shop) do
    Shop.create!(name: 'A Mafalda', token: 'a1b2c3d4e5', host: 'vnda.com.br')
  end

  describe 'GET /:shop_name/:code' do
    it 'returns 404 without tracking' do
      get(
        '/a-mafalda/OH155174043BR',
        params: { token: shop.token }
      )

      expect(response).to have_http_status(:not_found)
    end

    context 'with tracking' do
      before do
        Tracking.create(
          shop_id: shop.id, code: 'tracking-123', delivery_status: 'pending'
        )

        get(
          '/a-mafalda/tracking-123',
          params: { token: shop.token }
        )
      end

      it { expect(response_content).to include('tracking-123') }
      it do
        expect(response_content).to include('Aguardando postagem do pedido')
      end
    end
  end
end
