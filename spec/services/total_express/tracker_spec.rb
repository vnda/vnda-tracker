# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TotalExpress::Tracker do
  subject(:tracker) { described_class.new(shop) }

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
  let(:code) { 'VN21968' }
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

  describe '.status' do
    subject(:status) { tracker.status(code) }

    let(:expected) do
      {
        date: '2020-08-10 06:25:50 +0000',
        status: 'in_transit',
        message: 'RECEBIDO CD DE: - - VIX'
      }
    end

    it 'returns status in transit' do
      expect(status).to eq(expected)
    end
  end
end
