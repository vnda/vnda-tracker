# frozen_string_literal: true

require 'rails_helper'

describe Carrier, type: :model do
  subject(:carrier) { described_class }

  let(:shop) { ::Shop.create!(shop_attributes) }

  let(:shop_attributes) do
    {
      'name': 'Shop 1',
      'token': 'shop1_token',
      'notification_url': 'http://shop1.vnda.com.br',
      'tnt_email': '',
      'tnt_cnpj': '',
      'tnt_enabled': false,
      'intelipost_api_key': '',
      'intelipost_id': '',
      'intelipost_enabled': false,
      'forward_to_intelipost': false,
      'jadlog_enabled': true,
      'jadlog_registered_cnpj': '32124427000198',
      'jadlog_user_code': '12345',
      'jadlog_password': 'pwd1',
      'total_enabled': true,
      'total_client_id': '123',
      'total_user': 'foo',
      'total_password': 'bar'
    }
  end

  describe '.discover' do
    it 'recognizes correios tracking code' do
      tracker = carrier.discover('OF323444460BR')
      expect(tracker).to eq('correios')
    end

    it 'recognizes correios tracking code with lowercase characters' do
      tracker = carrier.discover('of323444460br')
      expect(tracker).to eq('correios')
    end

    it 'recognizes jadlog 14 digit tracking code' do
      tracker = carrier.discover('10084882066034')
      expect(tracker).to eq('jadlog')
    end

    it 'recognizes jadlog 8 digit tracking code' do
      tracker = carrier.discover('80605889')
      expect(tracker).to eq('jadlog')
    end

    it 'recognizes total_express tracking code' do
      tracker = carrier.discover('VN123')
      expect(tracker).to eq('totalexpress')
    end

    it 'does not recognize unexpected tracking code' do
      tracker = carrier.discover('of00000000000000br')
      expect(tracker).to eq('unknown')
    end
  end

  describe '#service' do
    it 'raises error with an unsupported carrier' do
      expect { carrier.new(shop, 'foo').service }.to raise_error(
        Carrier::UnsupportedCarrierError,
        'Carrier foo is unsupported'
      )
    end

    it 'returns jadlog tracker instance' do
      service = carrier.new(shop, 'jadlog').service
      expect(service).to be_a(Jadlog)
    end

    it 'returns tnt tracker instance' do
      service = carrier.new(shop, 'tnt').service
      expect(service).to be_a(Tnt)
    end

    it 'returns correios tracker instance' do
      service = carrier.new(shop, 'correios').service
      expect(service).to be_a(Correios)
    end

    context 'with Correios from Postmon' do
      before { ENV['CORREIOS_DATA_FROM'] = 'postmon' }
      after { ENV['CORREIOS_DATA_FROM'] = nil }

      it 'returns postmon tracker instance' do
        service = carrier.new(shop, 'correios').service
        expect(service).to be_a(Postmon)
      end
    end

    context 'with Correios from HTML parser' do
      before { ENV['CORREIOS_DATA_FROM'] = 'html' }
      after { ENV['CORREIOS_DATA_FROM'] = nil }

      it 'returns correios html tracker instance' do
        service = carrier.new(shop, 'correios').service
        expect(service).to be_a(CorreiosHtml)
      end
    end
  end

  describe '.url' do
    it 'returns correios url' do
      url = carrier.url(carrier: 'correios', code: 'code123')
      expect(url)
        .to eq('https://track.aftership.com/brazil-correios/code123')
    end

    it 'returns tnt url' do
      url = carrier.url(carrier: 'tnt', code: 'code123')
      expect(url)
        .to eq('http://app.tntbrasil.com.br/radar/public/'\
          'localizacaoSimplificadaDetail/code123')
    end

    it 'returns jadlog url' do
      url = carrier.url(carrier: 'jadlog', code: 'code123')
      expect(url)
        .to eq('http://www.jadlog.com.br/siteDpd/''tracking.jad?cte=code123')
    end

    it 'returns totalexpress url' do
      url = carrier.url(carrier: 'totalexpress', code: 'VN123', shop: shop)
      expect(url)
        .to eq('https://tracking.totalexpress.com.br/poupup_track.php?reid=123'\
               '&pedido=VN123&nfiscal=123')
    end
  end

  private

  def stub_get_wsdl
    stub_request(
      :get,
      'http://www.jadlog.com/JadlogEdiWs/services/TrackingBean?WSDL'
    ).to_return(
      status: 200,
      body: Rails.root.join(
        'spec', 'fixtures', 'jadlogDefinition.xml'
      ).read
    )
  end

  def stub_tracking(response)
    stub_request(
      :post,
      'http://www.jadlog.com/JadlogEdiWs/services/TrackingBean'
    ).with(
      headers: { 'Soapaction' => '"consultar"' }
    ).to_return(status: 200, body: response)
  end
end
