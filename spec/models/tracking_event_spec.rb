# frozen_string_literal: true

require 'rails_helper'

describe TrackingEvent, type: :model do
  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      notification_url: 'http://shop1.vnda.com.br'
    )
  end

  let(:tracking) do
    Tracking.create!(
      shop: shop,
      code: 'PM135787152BR',
      delivery_status: 'pending'
    )
  end

  describe '#register' do
    it 'raises error if no delivery_status' do
      expect do
        tracking.events.register(nil, Time.current, 'Objeto postado')
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'registers an event' do
      tracking.events.register('in_transit', Time.current, 'Objeto postado')

      expect(tracking.events.size).to eq(1)
    end
  end
end
