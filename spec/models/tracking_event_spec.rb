# frozen_string_literal: true

require 'rails_helper'

describe TrackingEvent, type: :model do
  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      host: 'shop1.vnda.com.br'
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
    context 'without event' do
      let(:events) { [] }

      it { expect(tracking.events.size).to eq(0) }
    end

    context 'with invalid' do
      let(:events) do
        [
          {
            date: Time.current,
            status: nil,
            message: 'Objeto postado'
          }
        ]
      end

      it { expect(tracking.events.size).to eq(0) }
    end

    context 'with event' do
      let(:events) do
        [
          {
            date: Time.current,
            status: 'in_transit',
            message: 'Objeto postado'
          }
        ]
      end

      before { tracking.events.register(events, tracking) }

      it { expect(tracking.events.size).to eq(1) }
    end

    context 'with events' do
      let(:events) do
        [
          {
            date: Time.current,
            status: 'in_transit',
            message: 'Objeto postado'
          },
          {
            date: Time.current,
            status: 'delivered',
            message: 'Objeto entregue'
          }
        ]
      end

      before { tracking.events.register(events, tracking) }

      it { expect(tracking.events.size).to eq(2) }
      it { expect(tracking.events[0].delivery_status).to eq('in_transit') }
      it { expect(tracking.events[1].delivery_status).to eq('delivered') }
    end
  end
end
