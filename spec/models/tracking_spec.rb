# frozen_string_literal: true

require 'rails_helper'

describe Tracking, type: :model do
  subject(:tracking) { Tracking.create!(tracking_attributes) }

  let(:forward_to_intelipost) { false }
  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      notification_url: 'http://shop1.vnda.com.br',
      forward_to_intelipost: forward_to_intelipost
    )
  end

  let(:carrier) { 'correios' }

  let(:tracking_attributes) do
    {
      shop: shop,
      code: 'PM135787152BR',
      delivery_status: 'pending',
      carrier: carrier,
      package: 'BBA1B3509E-01'
    }
  end

  before { Timecop.freeze(Time.zone.parse('2018-06-12')) }
  after { Timecop.return }

  context 'without delivery_status' do
    let(:tracking_attributes) { { code: 'PM135787152BR' } }

    it 'raises validation error' do
      expect { tracking } .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'without code' do
    let(:tracking_attributes) do
      { delivery_status: 'pending', carrier: 'correios' }
    end

    it 'raises validation error' do
      expect { tracking } .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when shop is integrated with Intelipost' do
    let(:forward_to_intelipost) { true }

    it 'sends tracking to Intelopost on create' do
      allow(Intelipost).to receive(:new).with(shop).and_return(
        intelipost_service = instance_double(Intelipost)
      )

      expect(intelipost_service).to receive(:update_tracking)
        .with('BBA1B3509E-01', 'PM135787152BR')

      tracking
    end
  end

  describe '#searchable' do
    it 'returns tracking code' do
      expect(tracking.searchable).to eq('PM135787152BR')
    end

    context 'with Interlipost as carrier' do
      let(:carrier) { 'intelipost' }

      it 'returns package' do
        expect(tracking.searchable).to eq('BBA1B3509E-01')
      end
    end
  end

  describe '#has_job?' do
    subject(:has_job) { tracking.has_job? }

    let(:jobs) { [instance_double(Sidekiq::SortedEntry)] }

    before do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return(
        ss = instance_double(Sidekiq::ScheduledSet)
      )

      allow(ss).to receive(:find).and_return(jobs)
    end

    it { expect(has_job).to eq(true) }

    context 'without scheduled job' do
      let(:jobs) { [] }

      it { expect(has_job).to eq(false) }
    end
  end

  describe '#update_status!' do
    let(:checkpoint_at) { '2018-06-12 17:36:44 +0000'.to_datetime }

    before do
      allow(Carrier).to receive(:new).with(shop, 'correios').and_return(
        carrier_service = instance_double(Carrier)
      )

      allow(carrier_service).to receive(:status).with('PM135787152BR')
        .and_return(
          date: checkpoint_at,
          status: 'in_transit',
          message: 'Objeto postado'
        )
    end

    it 'updates delivery_status' do
      expect { tracking.update_status! } .to(
        change(tracking, :delivery_status).from('pending').to('in_transit')
      )
    end

    it 'updates last_checkpoint_at' do
      expect { tracking.update_status! } .to(
        change(tracking, :last_checkpoint_at).from(nil).to(
          '2018-06-12 17:36:44 +0000'.to_datetime
        )
      )
    end

    it 'registers events' do
      tracking.update_status!
      expect(tracking.events.size).to eq(1)
    end

    context 'with checkpoint_at bigger than 30 days' do
      let(:checkpoint_at) { '2018-04-12 17:36:44 +0000'.to_datetime }

      it 'updates delivery_status to "expired"' do
        tracking.last_checkpoint_at = checkpoint_at

        expect { tracking.update_status! } .to(
          change(tracking, :delivery_status).from('pending').to('expired')
        )
      end
    end
  end
end
