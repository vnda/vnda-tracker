# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TotalExpress::DocumentReader do
  subject(:status) { described_class.parse(shop: shop, code: code) }

  let(:shop) { Shop.create!(shop_attributes) }
  let(:code) { 'VN123' }
  let(:file_name) { 'total_express_with_tracking.html' }
  let(:tracking_page) do
    Rails.root.join('spec', 'fixtures', file_name).read
  end

  before { stub_total_express }

  describe '#parse' do
    context 'when in_transit' do
      let(:tracking_html) do
        tracking_page.gsub('$status', 'RECEBIDO NO CENTRO DE DISTRIBUIÇÃO')
      end

      it { is_expected.to eq('in_transit') }
    end

    context 'when out_of_delivery' do
      let(:tracking_html) do
        tracking_page.gsub('$status', 'SEPARADO PARA O ROTEIRO DE ENTREGA')
      end

      it { is_expected.to eq('out_of_delivery') }
    end

    context 'when delivered' do
      let(:tracking_html) do
        tracking_page.gsub('$status', 'ENTREGA REALIZADA (mobile) - Parente')
      end

      it { is_expected.to eq('delivered') }
    end

    context 'with exception' do
      let(:file_name) { 'total_express_without_tracking.html' }
      let(:tracking_html) { tracking_page }

      it { is_expected.to eq('exception') }
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
