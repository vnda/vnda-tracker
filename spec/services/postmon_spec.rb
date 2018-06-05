# frozen_string_literal: true

require 'rails_helper'

describe Postmon do
  subject { described_class.new }

  let(:url) { 'http://api.postmon.com.br/v1/rastreio/ect' }

  describe '#status' do
    it 'returns tracking code status' do
      stub_request(:get, "#{url}/DW962413465BR")
        .to_return(status: 200, body: response_with_event.to_json)

      expect(subject.status('DW962413465BR')).to eq(
        date: '04/04/2018 17:14 -3UTC'.to_datetime, status: 'delivered'
      )
    end

    it 'returns pending when does not have events' do
      stub_request(:get, "#{url}/DW962413465BR")
        .to_return(status: 404)

      expect(subject.status('DW962413465BR')).to eq(
        date: nil, status: 'pending'
      )
    end
  end

  describe '#parse_status' do
    STATUSES = {
      'Objeto postado' => 'in_transit',
      'Postado depois do horário limite da agência' => 'in_transit',
      'Objeto encaminhado' => 'in_transit',
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

    STATUSES.each do |postmon_status, app_status|
      it 'returns parsed status' do
        expect(subject.parse_status(postmon_status)).to eq(app_status)
      end
    end

    context 'with unexpected status' do
      it 'returns "exception" status' do
        expect(subject.parse_status('foo')).to eq('exception')
      end
    end
  end

  def response_with_event
    {
      codigo: 'DW962413465BR',
      servico: 'ect',
      historico: [
        {
          detalhes: '',
          local: 'SAO PAULO/SP',
          data: '03/04/2018 15:04',
          situacao: 'Objeto postado'
        },
        {
          detalhes: '',
          local: 'SAO BERNARDO DO CAMPO/SP',
          data: '04/04/2018 17:14',
          situacao: 'Objeto entregue ao destinat\u00ef\u00bf\u00bdrio'
        }
      ]
    }
  end
end
