# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TotalExpress::StatusReader do
  subject(:status) { described_class.new(shop, code) }

  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      notification_url: 'http://shop1.vnda.com.br',
      total_enabled: true,
      total_client_id: '123',
      total_user: 'foo',
      total_password: 'bar'
    )
  end
  let(:request) do
    File.readlines('spec/fixtures/total_express_request.xml', chomp: true)[0]
  end

  let(:code) { 'VN21952' }

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

  describe '#parse' do
    context 'when order in transit' do
      let(:code) { 'VN21968' }

      it 'returns status in transit' do
        expect(status.parse[:status]).to eq('in_transit')
      end
    end

    context 'when order out of delivery' do
      let(:code) { 'VN21863' }

      it 'returns status out of delivery' do
        expect(status.parse[:status]).to eq('out_of_delivery')
      end
    end

    context 'when order delivered' do
      it 'returns status delivered' do
        expect(status.parse[:status]).to eq('delivered')
      end
    end

    context 'with order exception' do
      let(:code) { 'VN22040' }

      it 'returns status exception' do
        expect(status.parse[:status]).to eq('exception')
      end
    end

    context 'without order' do
      let(:code) { '9999999' }

      it 'returns status exception' do
        expect(status.parse[:status]).to eq('pending')
      end
    end
  end
end
