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
      'jadlog_password': 'pwd1'
    }
  end

  describe '.discover' do
    it 'recognizes correios tracking code' do
      tracker = carrier.discover('OF323444460BR')
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
  end

  describe '#service' do
    it 'returns jadlog tracker instance' do
      service = carrier.new(shop, 'jadlog').service
      expect(service).to be_a(Jadlog::Tracker)
    end

    it 'returns tnt tracker instance' do
      service = carrier.new(shop, 'tnt').service
      expect(service).to be_a(Tnt)
    end

    it 'returns correios tracker instance' do
      service = carrier.new(shop, 'correios').service
      expect(service).to be_a(Correios)
    end

    it 'returns postmon tracker instance' do
      ENV['CORREIOS_FROM_POSTMON'] = 'true'
      service = carrier.new(shop, 'correios').service
      expect(service).to be_a(Postmon)
    end
  end

  describe '.url' do
    it 'returns correios url' do
      url = carrier.url('correios', 'code123')
      expect(url)
        .to eq('https://track.aftership.com/brazil-correios/code123')
    end

    it 'returns tnt url' do
      url = carrier.url('tnt', 'code123')
      expect(url)
        .to eq('http://app.tntbrasil.com.br/radar/public/'\
          'localizacaoSimplificadaDetail/code123')
    end

    it 'returns jadlog url' do
      url = carrier.url('jadlog', 'code123')
      expect(url)
        .to eq('http://www.jadlog.com.br/siteDpd/''tracking.jad?cte=code123')
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
