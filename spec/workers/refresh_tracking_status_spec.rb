# frozen_string_literal: true

require 'rails_helper'

describe RefreshTrackingStatus do
  around { |example| Sidekiq::Testing.fake! { example.run } }

  let(:delivery_status) { 'pending' }
  let(:tracking) do
    Tracking.create!(
      code: 'PP423230351BR',
      delivery_status: delivery_status,
      shop: Shop.create(name: 'foo')
    )
  end

  before { Timecop.freeze(Time.zone.parse('2018-02-28')) }
  after { Timecop.return }

  it 'schedules next verification if delivery status not change' do
    expect(Tracking).to receive(:find).with(tracking.id).and_return(tracking)
    expect(tracking).to receive(:update_status!).and_return(false)

    expect(described_class)
      .to receive(:perform_at)
      .with(24.hours.from_now, tracking.id)

    subject.perform(tracking.id)
  end

  context 'when delivery status was changed' do
    before do
      expect(Tracking).to receive(:find).with(tracking.id).and_return(tracking)
      expect(tracking).to receive(:update_status!).and_return(true)
    end

    context 'to in_transit' do
      let(:delivery_status) { 'in_transit' }

      it 'schedules next verification and send notification' do
        expect(described_class)
          .to receive(:perform_at)
          .with(24.hours.from_now, tracking.id)

        expect(Notify)
          .to receive(:perform_async)
          .with(tracking.id)

        subject.perform(tracking.id)
      end
    end

    context 'to delivered' do
      let(:delivery_status) { 'delivered' }

      it 'sends notification' do
        expect(Notify)
          .to receive(:perform_async)
          .with(tracking.id)

        subject.perform(tracking.id)
      end

      context 'with retention days' do
        before do
          expect(ENV)
            .to receive(:[])
            .with('TRACKING_CODE_RETENTION_DAYS')
            .and_return(1)
        end

        it 'schedules tracking deletation and send notification' do
          expect(DeleteTracking)
            .to receive(:perform_at)
            .with(1.day.from_now, tracking.id)

          expect(Notify)
            .to receive(:perform_async)
            .with(tracking.id)

          subject.perform(tracking.id)
        end
      end
    end

    context 'to out_of_delivery' do
      let(:delivery_status) { 'out_of_delivery' }

      it 'schedules next verification' do
        expect(described_class)
          .to receive(:perform_at)
          .with(24.hours.from_now, tracking.id)

        subject.perform(tracking.id)
      end
    end

    context 'to failed_attempt' do
      let(:delivery_status) { 'failed_attempt' }

      it 'schedules next verification' do
        expect(described_class)
          .to receive(:perform_at)
          .with(24.hours.from_now, tracking.id)

        subject.perform(tracking.id)
      end
    end

    context 'to expired' do
      let(:delivery_status) { 'expired' }

      it 'schedules next verification' do
        subject.perform(tracking.id)
      end
    end

    context 'to an unexpected status' do
      let(:delivery_status) { 'foo' }

      it 'schedules next verification' do
        expect(described_class)
          .to receive(:perform_at)
          .with(24.hours.from_now, tracking.id)

        subject.perform(tracking.id)
      end
    end
  end
end
