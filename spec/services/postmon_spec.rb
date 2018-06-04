# frozen_string_literal: true

require 'rails_helper'

describe Postmon do
  subject { described_class.new }

  let(:url) { 'http://api.postmon.com.br/v1/rastreio/ect' }

  describe '.status' do
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
