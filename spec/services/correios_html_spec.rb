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

      it do
        expect(status).to eq(
          date: '27/08/2018 12:43'.to_datetime,
          status: 'delivered',
          message: 'Objeto entregue ao destinatário'
        )
      end
    end

    context 'when response does not have events' do
      subject(:status) { correios.status('OF526556823BR') }

      before do
        stub_request(:post, url)
          .with(body: { 'objetos' => 'OF526556823BR' })
          .to_return(status: 200, body: html_without_events)
      end

      it { is_expected.to eq(date: nil, status: 'pending', message: nil) }
    end

    context 'with an Excon error' do
      subject(:status) { correios.status('OF526556823BR') }

      before { stub_request(:post, url).to_return(status: 500) }

      it { is_expected.to eq(date: nil, status: 'pending', message: nil) }
    end
  end

  describe '#parse_status' do
    STATUSES = {
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
      'Objeto entregue ao destinatário' => 'delivered',
      'Objeto entregue' => 'delivered',
      'Objeto devolvido ao remetente' => 'expired'
    }.freeze

    STATUSES.each do |correios_status, app_status|
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
