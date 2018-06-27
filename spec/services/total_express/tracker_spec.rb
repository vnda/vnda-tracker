# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TotalExpress::Tracker do
  subject(:tracker) { described_class.new(shop) }

  let(:shop) { Shop.create!(shop_attributes) }
  let(:code) { 'VN123' }
  let(:file_name) { 'total_express_with_tracking.html' }
  let(:tracking_page) { Rails.root.join('spec', 'fixtures', file_name).read }
  let(:tracking_html) do
    tracking_page.gsub('$status', 'RECEBIDO NO CENTRO DE DISTRIBUIÇÃO')
  end

  before do
    Timecop.freeze('2018-06-12 17:36:44 +0000')
    stub_total_express
  end

  after { Timecop.return }

  describe '.status' do
    subject(:status) { tracker.status(code) }

    let(:expected) do
      {
        date: '2018-06-12 17:36:44.000000000 +0000',
        status: 'in_transit'
      }
    end

    it { is_expected.to eq(expected) }
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
