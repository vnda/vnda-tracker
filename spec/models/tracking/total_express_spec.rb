# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tracking do
  let(:shop) { Shop.create!(shop_attributes) }

  let(:tracking) { shop.trackings.create!(tracking_attributes) }

  let(:tracking_url) do
    'https://tracking.totalexpress.com.br/poupup_track.php?reid=123&'\
    'pedido=VN123&nfiscal=123'
  end

  let(:tracking_page) do
    Rails.root.join('spec', 'fixtures', 'total_express_with_tracking.html').read
  end

  before { stub_total_express }

  describe '#update_status!' do
    subject(:update_status) { tracking.update_status! }

    let(:tracking_html) do
      tracking_page.gsub('$status', 'ENTREGA REALIZADA')
    end

    before { Timecop.freeze('2018-06-12 17:36:44 +0000') }
    after { Timecop.return }

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
            '2018-06-12 17:36:44 +0000'.to_datetime
          )
        )
      end

      it 'registers an event' do
        update_status
        expect(tracking.events.size).to eq(1)
      end
    end

    context 'without changes' do
      let(:tracking_html) do
        tracking_page.gsub('$status', 'ENTREGA REALIZADA')
      end

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

  private

  def shop_attributes
    {
      name: 'Shop 1',
      token: 'shop1_token',
      notification_url: 'http://shop1.vnda.com.br',
      total_enabled: true,
      total_client_id: '123',
      total_user: 'foo',
      total_password: 'bar'
    }
  end

  def tracking_attributes
    {
      code: 'VN123',
      package: '22790D9A33-01'
    }
  end

  def stub_total_express
    stub_request(:get, 'https://tracking.totalexpress.com.br/poupup_track.php?')
      .with(
        query: {
          'nfiscal' => 123,
          'pedido' => 'VN123',
          'reid' => 123
        }
      )
      .to_return(status: 200, body: tracking_html)
  end
end
