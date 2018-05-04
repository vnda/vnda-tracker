# frozen_string_literal: true

require 'rails_helper'

describe Jadlog::Tracker, type: :service do
  subject(:tracker) { described_class }

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
  let(:successful_response) do
    <<~XML
      <soapenv:Envelope
        xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <soapenv:Body>
          <consultarResponse
            xmlns="http://jadlogEdiws">
            <consultarReturn>
              <![CDATA[
                <?xml version="1.0" encoding="utf-8" ?>
                <string
                  xmlns="http://www.jadlog.com.br/JadlogWebService/services">
                  <Jadlog_Tracking_Consultar>
                    <ND>
                      <Numero>10084882066034</Numero>
                      <Status>ENTREGUE</Status>
                      <DataHoraEntrega>02/07/2013</DataHoraEntrega>
                      <Recebedor>LEANDRO</Recebedor>
                      <Documento>2971132</Documento>
                      <ChaveAcesso>
                        31130604884082001530570000006754471006754475
                      </ChaveAcesso>
                      <Cte>00675447</Cte>
                      <Serie>000</Serie>
                      <DataEmissao>27/06/2013</DataEmissao>
                      <Valor>22.39</Valor>
                    </ND>
                  </Jadlog_Tracking_Consultar>
                </string>
              ]]>
            </consultarReturn>
          </consultarResponse>
        </soapenv:Body>
      </soapenv:Envelope>
    XML
  end
  let(:error_response) do
    <<~XML
      <soapenv:Envelope
        xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <soapenv:Body>
          <consultarResponse
            xmlns="http://jadlogEdiws">
            <consultarReturn>
              <![CDATA[
                <?xml version="1.0" encoding="utf-8" ?>
                <string
                  xmlns="http://www.jadlog.com.br/JadlogEdiWs/services">
                  <Jadlog_Tracking_Consultar>
                    <versao>1.0</versao>
                    <Retorno>-1</Retorno>
                    <Mensagem>CT-e Jadlog pesquisado não está ativo.</Mensagem>
                  </Jadlog_Tracking_Consultar>
                </string>
              ]]>
            </consultarReturn>
          </consultarResponse>
        </soapenv:Body>
      </soapenv:Envelope>
    XML
  end

  describe '#status' do
    it 'returns correct status' do
      stub_get_wsdl
      stub_tracking(successful_response)
      status = tracker.new(shop).status('80605889')
      expect(status[:status]).to eq('delivered')
    end

    context 'when an error occurs' do
      it 'returns the error' do
        stub_get_wsdl
        stub_tracking(error_response)
        status = tracker.new(shop).status('80605889')
        expect(status[:status]).to eq('CT-e Jadlog pesquisado não está ativo.')
      end
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
