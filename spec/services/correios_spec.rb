# frozen_string_literal: true

require 'rails_helper'

describe Correios do
  subject(:correios) { described_class.new }

  let(:url) { 'http://webservice.correios.com.br/service/rastro/Rastro.wsdl' }

  describe '#status' do
    before do
      stub_request(
        :get,
        'http://webservice.correios.com.br/service/rastro/Rastro.wsdl'
      ).to_return(status: 200, body: wsdl)
    end

    it 'returns tracking code status' do
      stub_request(
        :post,
        'http://webservice.correios.com.br/service/rastro'
      ).with(body: request_xml).to_return(
        status: 200,
        body: xml_with_event
      )

      expect(correios.status('DW962413465BR')).to eq(
        date: '08/06/2018 16:09 -3UTC'.to_datetime,
        status: 'in_transit',
        message: 'Objeto postado'
      )
    end

    it 'returns pending when does not have events' do
      stub_request(
        :post,
        'http://webservice.correios.com.br/service/rastro'
      ).with(body: request_xml).to_return(
        status: 200,
        body: xml_without_event
      )

      expect(correios.status('DW962413465BR')).to eq(
        date: nil,
        status: 'pending',
        message: nil
      )
    end
  end

  describe '#events' do
    before do
      stub_request(
        :get,
        'http://webservice.correios.com.br/service/rastro/Rastro.wsdl'
      ).to_return(status: 200, body: wsdl)
    end

    it 'returns tracking code status' do
      stub_request(
        :post,
        'http://webservice.correios.com.br/service/rastro'
      ).with(body: request_xml).to_return(
        status: 200,
        body: xml_with_event
      )

      expect(correios.events('DW962413465BR')).to eq(
        [
          {
            date: '08/06/2018 16:09 -3UTC'.to_datetime,
            status: 'in_transit',
            message: 'Objeto postado'
          }
        ]
      )
    end
  end

  describe '#last_response' do
    before do
      stub_request(
        :get,
        'http://webservice.correios.com.br/service/rastro/Rastro.wsdl'
      ).to_return(status: 200, body: wsdl)

      stub_request(
        :post,
        'http://webservice.correios.com.br/service/rastro'
      ).with(body: request_xml).to_return(
        status: 200,
        body: xml_with_event
      )

      correios.events('DW962413465BR')
    end

    it 'returns last response body' do
      expect(correios.last_response).to eq(xml_with_event)
    end
  end

  describe '#parse_status' do
    statuses = {
      'PO-01' => 'in_transit',
      'PO-09' => 'in_transit',
      'RO-01' => 'in_transit',
      'DO-01' => 'in_transit',
      'OEC-01' => 'out_of_delivery',
      'BDE-20' => 'out_of_delivery',
      'BDI-20' => 'out_of_delivery',
      'BDR-20' => 'out_of_delivery',
      'BDE-25' => 'out_of_delivery',
      'BDI-25' => 'out_of_delivery',
      'BDR-25' => 'out_of_delivery',
      'BDE-34' => 'out_of_delivery',
      'BDI-34' => 'out_of_delivery',
      'BDR-34' => 'out_of_delivery',
      'BDE-35' => 'out_of_delivery',
      'BDI-35' => 'out_of_delivery',
      'BDR-35' => 'out_of_delivery',
      'BDE-46' => 'out_of_delivery',
      'BDI-46' => 'out_of_delivery',
      'BDR-46' => 'out_of_delivery',
      'BDE-47' => 'out_of_delivery',
      'BDI-47' => 'out_of_delivery',
      'BDR-47' => 'out_of_delivery',
      'BDE-01' => 'delivered',
      'BDI-01' => 'delivered',
      'BDR-01' => 'delivered',
      'BDE-23' => 'expired',
      'BDI-23' => 'expired',
      'BDR-23' => 'expired',
      'foo' => 'exception'
    }.freeze

    statuses.each do |postmon_status, app_status|
      it 'returns parsed status' do
        expect(correios.parse_status(postmon_status)).to eq(app_status)
      end
    end

    context 'with unexpected status' do
      it 'returns "exception" status' do
        expect(correios.parse_status('foo')).to eq('exception')
      end
    end
  end

  def xml_with_event
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
        <soapenv:Header>
          <X-OPNET-Transaction-Trace:X-OPNET-Transaction-Trace xmlns:X-OPNET-Transaction-Trace="http://opnet.com">pid=5108,requestid=5b99c9dd8308f75ac09b1f4db9411fa2482925b94a3655b2</X-OPNET-Transaction-Trace:X-OPNET-Transaction-Trace>
        </soapenv:Header>
        <soapenv:Body>
          <ns2:buscaEventosResponse xmlns:ns2="http://resource.webservice.correios.com.br/">
            <return>
              <versao>2.0</versao>
              <qtd>1</qtd>
              <objeto>
                <numero>PM135787152BR</numero>
                <sigla>PM</sigla>
                <nome>ENCOMENDA PAC (ETIQ F\xC3\x8DSICA)</nome>
                <categoria>ENCOMENDA PAC</categoria>
                <evento>
                  <tipo>PO</tipo>
                  <status>01</status>
                  <data>08/06/2018</data>
                  <hora>16:09</hora>
                  <descricao>Objeto postado</descricao>
                  <local>AC AGUA BRANCA</local>
                  <codigo>05001970</codigo>
                  <cidade>SAO PAULO</cidade>
                  <uf>SP</uf>
                </evento>
              </objeto>
            </return>
          </ns2:buscaEventosResponse>
        </soapenv:Body>
      </soapenv:Envelope>
    XML
  end

  def xml_without_event
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
        <soapenv:Header>
          <X-OPNET-Transaction-Trace:X-OPNET-Transaction-Trace xmlns:X-OPNET-Transaction-Trace="http://opnet.com">pid=5108,requestid=5b99c9dd8308f75ac09b1f4db9411fa2482925b94a3655b2</X-OPNET-Transaction-Trace:X-OPNET-Transaction-Trace>
        </soapenv:Header>
        <soapenv:Body>
          <ns2:buscaEventosResponse xmlns:ns2="http://resource.webservice.correios.com.br/">
            <return>
              <versao>2.0</versao>
              <qtd>1</qtd>
              <objeto>
                <numero>PM135787152BR</numero>
                <sigla>PM</sigla>
                <nome>ENCOMENDA PAC (ETIQ F\xC3\x8DSICA)</nome>
                <categoria>ENCOMENDA PAC</categoria>
              </objeto>
            </return>
          </ns2:buscaEventosResponse>
        </soapenv:Body>
      </soapenv:Envelope>
    XML
  end

  # rubocop:disable  Metrics/MethodLength
  def request_xml
    '<?xml version="1.0" encoding="UTF-8"?>' \
    '<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" ' \
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' \
        'xmlns:tns="http://resource.webservice.correios.com.br/" ' \
        'xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' \
      '<env:Body>' \
        '<tns:buscaEventos>' \
          '<usuario>ECT</usuario>' \
          '<senha>SRO</senha>' \
          '<tipo>L</tipo>' \
          '<resultado>U</resultado>' \
          '<lingua>101</lingua>' \
          '<objetos>DW962413465BR</objetos>' \
        '</tns:buscaEventos>' \
      '</env:Body>' \
    '</env:Envelope>'
  end
  # rubocop:enable  Metrics/MethodLength

  def wsdl
    <<~XML
      <definitions xmlns:wsp1_2="http://schemas.xmlsoap.org/ws/2004/09/policy" xmlns="http://schemas.xmlsoap.org/wsdl/" xmlns:wsp="http://www.w3.org/ns/ws-policy" xmlns:wsam="http://www.w3.org/2007/05/addressing/metadata" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:tns="http://resource.webservice.correios.com.br/" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" name="rastro" targetNamespace="http://resource.webservice.correios.com.br/">
        <types>
          <xsd:schema>
            <xsd:import namespace="http://resource.webservice.correios.com.br/" schemaLocation="Rastro_schema1.xsd" />
          </xsd:schema>
        </types>
        <message name="buscaEventosLista">
          <part name="parameters" element="tns:buscaEventosLista"></part>
        </message>
        <message name="buscaEventosResponse">
          <part name="parameters" element="tns:buscaEventosResponse"></part>
        </message>
        <message name="buscaEventosListaResponse">
          <part name="parameters" element="tns:buscaEventosListaResponse"></part>
        </message>
        <message name="buscaEventos">
          <part name="parameters" element="tns:buscaEventos"></part>
        </message>
        <portType name="Service">
          <operation name="buscaEventos">
            <input message="tns:buscaEventos" wsam:Action="buscaEventos"></input>
            <output message="tns:buscaEventosResponse" wsam:Action="http://resource.webservice.correios.com.br/Service/buscaEventosResponse"></output>
          </operation>
          <operation name="buscaEventosLista">
            <input message="tns:buscaEventosLista" wsam:Action="buscaEventosLista"></input>
            <output message="tns:buscaEventosListaResponse" wsam:Action="http://resource.webservice.correios.com.br/Service/buscaEventosListaResponse"></output>
          </operation>
        </portType>
        <binding name="ServicePortBinding" type="tns:Service">
          <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http" />
          <operation name="buscaEventos">
            <soap:operation soapAction="buscaEventos" />
            <input>
              <soap:body use="literal" />
            </input>
            <output>
              <soap:body use="literal" />
            </output>
          </operation>
          <operation name="buscaEventosLista">
            <soap:operation soapAction="buscaEventosLista" />
            <input>
              <soap:body use="literal" />
            </input>
            <output>
              <soap:body use="literal" />
            </output>
          </operation>
        </binding>
        <service name="rastro">
          <port name="ServicePort" binding="tns:ServicePortBinding">
            <soap:address location="http://webservice.correios.com.br:80/service/rastro" />
          </port>
        </service>
      </definitions>
    XML
  end
end
