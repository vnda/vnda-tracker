# frozen_string_literal: true

require 'rails_helper'

describe Notify do
  around { |example| Sidekiq::Testing.fake! { example.run } }

  subject(:worker) { described_class.new }

  let(:shop) { Shop.create(name: 'foo', notification_url: 'http://foo.com') }
  let(:tracking) do
    Tracking.create!(
      code: 'PP423230351BR',
      delivery_status: 'pending',
      shop: shop
    )
  end

  context 'without notfication url on shop' do
    let(:shop) { Shop.create(name: 'foo') }

    it 'does not send notification' do
      expect(worker.perform(tracking.id)).to eq(false)
    end
  end

  it 'sends notification' do
    stub_request(:post, 'http://foo.com/')
      .with(body: tracking.attributes.to_json)
      .to_return(status: 200, body: '')

    expect(worker.perform(tracking.id)).to eq(true)
  end

  it 'stores notification response' do
    stub_request(:post, 'http://foo.com/')
      .with(body: tracking.attributes.to_json)
      .to_return(status: 200, body: 'OK')

    worker.perform(tracking.id)

    expect(tracking.notifications.first.response).to eq('OK')
  end
end
