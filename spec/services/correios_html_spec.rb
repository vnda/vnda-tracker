# frozen_string_literal: true

require 'rails_helper'

describe CorreiosHtml do
  subject(:correios) { described_class.new }

  let(:html_with_events) do
    Rails.root.join('spec', 'fixtures', 'correios-with-events.html').read
  end

  let(:html_without_events) do
    Rails.root.join('spec', 'fixtures', 'correios-without-events.html').read
  end

  let(:url) do
    'https://www2.correios.com.br/sistemas/rastreamento/resultado.cfm'
  end

  describe '#status' do
    context 'with events' do
      subject(:status) { correios.status('OF526553827BR') }

      before do
        stub_request(:post, url)
          .with(body: { 'objetos' => 'OF526553827BR' })
          .to_return(status: 200, body: html_with_events)
      end

      it 'returns last event' do
        expect(status).to eq(
          date: '27/08/2018 12:43 -3UTC'.to_datetime,
          status: 'delivered',
          message: 'Objeto entregue ao destinatário'
        )
      end

      it 'registers the history' do
        status
        expect(CorreiosHistory.last.code).to eq('OF526553827BR')
        expect(CorreiosHistory.last.response_body).to eq(html_with_events)
        expect(CorreiosHistory.last.response_status).to eq(200)
      end
    end

    context 'when response does not have events' do
      subject(:status) { correios.status('OF526556823BR') }

      before do
        stub_request(:post, url)
          .with(body: { 'objetos' => 'OF526556823BR' })
          .to_return(status: 200, body: html_without_events)
      end

      it 'returns default event' do
        expect(status).to eq(date: nil, status: 'pending', message: nil)
      end

      it 'registers the history' do
        status
        expect(CorreiosHistory.last.code).to eq('OF526556823BR')
        expect(CorreiosHistory.last.response_body).to eq(html_without_events)
        expect(CorreiosHistory.last.response_status).to eq(200)
      end
    end

    context 'with an HTTP status error' do
      subject(:status) { correios.status('OF526556823BR') }

      before { stub_request(:post, url).to_return(status: 500) }

      it 'returns default event' do
        expect(status).to eq(date: nil, status: 'pending', message: nil)
      end

      it 'registers the history' do
        status
        expect(CorreiosHistory.last.code).to eq('OF526556823BR')
        expect(CorreiosHistory.last.response_body).to eq('')
        expect(CorreiosHistory.last.response_status).to eq(500)
      end
    end

    context 'with a generic Excon error' do
      subject(:status) { correios.status('OF526556823BR') }

      before do
        stub_request(:post, url).to_raise(Excon::Errors::Error, 'Error')
      end

      it 'returns default event' do
        expect(status).to eq(date: nil, status: 'pending', message: nil)
      end

      it 'registers the history' do
        status
        expect(CorreiosHistory.last.code).to eq('OF526556823BR')
        expect(CorreiosHistory.last.response_body).to eq('')
        expect(CorreiosHistory.last.response_status).to eq(nil)
      end
    end
  end

  describe '#events' do
    context 'with events' do
      subject(:events) { correios.events('OF526553827BR') }

      before do
        stub_request(:post, url)
          .with(body: { 'objetos' => 'OF526553827BR' })
          .to_return(status: 200, body: html_with_events)
      end

      it do
        expect(events).to eq(
          [
            {
              date: '27/08/2018 12:43 -3UTC'.to_datetime,
              message: 'Objeto entregue ao destinatário',
              status: 'delivered'
            },
            {
              date: '27/08/2018 9:59 -3UTC'.to_datetime,
              message: 'Objeto saiu para entrega ao destinatário',
              status: 'out_of_delivery'
            },
            {
              date: '25/08/2018 5:44 -3UTC'.to_datetime,
              message: "Objeto encaminhado\n               \n\n\n\n          " \
                '          de Unidade de Tratamento em SAO PAULO / SP para Un' \
                'idade de Distribuição em BARUERI / SP',
              status: 'in_transit'
            },
            {
              date: '24/08/2018 22:13 -3UTC'.to_datetime,
              message: "Objeto encaminhado\n               \n\n\n\n          " \
                '          de Unidade de Tratamento em PORTO ALEGRE / RS para' \
                ' Unidade de Tratamento em SAO PAULO / SP',
              status: 'in_transit'
            },
            {
              date: '24/08/2018 15:24 -3UTC'.to_datetime,
              message: "Objeto encaminhado\n               \n\n\n\n          " \
                '          de Agência dos Correios em Porto Alegre / RS para ' \
                'Unidade de Tratamento em PORTO ALEGRE / RS',
              status: 'in_transit'
            },
            {
              date: '24/08/2018 14:46 -3UTC'.to_datetime,
              message: 'Objeto postado',
              status: 'in_transit'
            }
          ]
        )
      end
    end
  end

  describe '#last_response' do
    context 'with response' do
      subject(:last_response) { correios.last_response }

      before do
        stub_request(:post, url)
          .with(body: { 'objetos' => 'OF526553827BR' })
          .to_return(status: 200, body: html_with_events)

        correios.status('OF526553827BR')
      end

      it 'returns the integration response' do
        expect(last_response.include?('tr')).to eq(true)
      end
    end
  end

  describe '#parse_status' do
    statuses = {
      'Objeto postado' => 'in_transit',
      'Objeto postado após o horário limite da unidade' => 'in_transit',
      'Postado depois do horário limite da agência' => 'in_transit',
      'Objeto encaminhado' => 'in_transit',
      'Objeto encaminhado de Unidade de Tratamento em BLUMENAU' => 'in_transit',
      "Objeto encaminhado \r\n\tde Unidade de Tratamento para Unidade de Dist" \
        'ribuição' => 'in_transit',
      'Saiu para Entrega' => 'out_of_delivery',
      'A entrega não pode ser efetuada' => 'out_of_delivery',
      'A entrega não pode ser efetuada - Carteiro não atendido' => 'out_of_de' \
        'livery',
      'A entrega ocorrerá no prox dia útil' => 'out_of_delivery',
      'Logradouro com numeração irregular' => 'out_of_delivery',
      'Coleta ou entrega de objeto não efetuada' => 'out_of_delivery',
      'Tentativa de entrega não efetuada' => 'out_of_delivery',
      'Saída para entrega cancelada' => 'out_of_delivery',
      'Objeto saiu para entrega ao destinatário' => 'out_of_delivery',
      'Carteiro não atendido' => 'out_of_delivery',
      'Objeto entregue ao destinatário' => 'delivered',
      'Objeto entregue' => 'delivered',
      'Objeto devolvido ao remetente' => 'expired',
      'Objeto em trânsito - por favor aguarde\r\n \r\n \t\r\nde \tUnidade de ' \
        'Tratamento \r\nem \tINDAIATUBA / SP\t\t\t\t\r\npara \tUnidade de ' \
          'Tratamento\t\t\t\t\r\nem \tSALVADOR / BA' => 'in_transit'
    }

    statuses.each do |correios_status, app_status|
      it 'returns parsed status' do
        expect(correios.parse_status(correios_status)).to eq(app_status)
      end
    end

    context 'with unexpected status' do
      it 'returns "exception" status' do
        expect(correios.parse_status('foo')).to eq('exception')
      end
    end
  end
end
