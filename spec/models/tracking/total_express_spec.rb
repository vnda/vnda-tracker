# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tracking do
  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      host: 'shop1.vnda.com.br',
      total_enabled: true,
      total_client_id: '123',
      total_user: 'foo',
      total_password: 'bar'
    )
  end

  let(:tracking_attributes) do
    {
      code: 'VN21952',
      package: '21952'
    }
  end

  let(:tracking) { shop.trackings.create!(tracking_attributes) }

  let(:request) do
    File.readlines('spec/fixtures/total_express_request.xml', chomp: true)[0]
  end

  before do
    stub_request(:get, 'https://edi.totalexpress.com.br/webservice24.php?wsdl')
      .to_return(
        status: 200,
        body: File.read('spec/fixtures/total_express.xml')
      )

    stub_request(:post, 'https://edi.totalexpress.com.br/webservice24.php')
      .with(
        body: request,
        headers: {
          'Authorization' => 'Basic Zm9vOmJhcg==',
          'Content-Length' => '433',
          'Content-Type' => 'text/xml;charset=UTF-8',
          'Host' => 'edi.totalexpress.com.br:443',
          'Soapaction' => '"ObterTracking"'
        }
      )
      .to_return(
        status: 200,
        body: File.read('spec/fixtures/total_express_with_tracking.xml'),
        headers: {}
      )

    Timecop.freeze(2020, 8, 10, 15, 20)
  end

  after { Timecop.return }

  describe '#update_status!' do
    subject(:update_status) { tracking.update_status! }

    context 'with changes' do
      it 'returns true' do
        expect(update_status).to eq(true)
      end

      it 'updates delivery_status' do
        expect { update_status } .to(
          change(tracking, :delivery_status).from('pending').to('delivered')
        )
      end

      it 'updates last_checkpoint_at' do
        expect { update_status } .to(
          change(tracking, :last_checkpoint_at).from(nil).to(
            '2020-08-10 08:39:14 -0300'.to_datetime
          )
        )
      end

      it 'registers an event' do
        update_status
        expect(tracking.events.size).to eq(1)
      end
    end

    context 'without changes' do
      before do
        tracking.update!(
          last_checkpoint_at: Time.current,
          delivery_status: 'delivered'
        )
      end

      it 'returns false' do
        expect(update_status).to eq(false)
      end
    end
  end
end
