# frozen_string_literal: true

require 'rails_helper'

describe Bling do
  subject(:bling) { described_class.new(shop) }

  let(:url) { 'https://bling.com.br/Api/v2/pedido/9988/json?apikey=f00ba9' }

  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      host: 'shop1.vnda.com.br',
      bling_api_key: 'f00ba9',
      bling_status_in_transit: 'Em andamento',
      bling_status_delivered: 'Atendido'
    )
  end

  let(:response_with_error) do
    {
      'retorno' => {
        'erros' => [
          {
            'erro' => {
              'cod' => 14,
              'msg' => 'A informacao desejada nao foi encontrada'
            }
          }
        ]
      }
    }
  end

  let(:response_with_order) do
    {
      'retorno' => {
        'pedidos' => [
          {
            'pedido' => {
              'desconto' => '0,00',
              'observacoes' => 'A5E068F9F4',
              'observacaointerna' => '',
              'data' => '2020-12-13',
              'numero' => '1234',
              'numeroOrdemCompra' => '',
              'vendedor' => '',
              'valorfrete' => '14.60',
              'totalprodutos' => '82.00',
              'totalvenda' => '96.60',
              'situacao' => status,
              'dataSaida' => '2020-12-13',
              'numeroPedidoLoja' => 'A5E068F9F4',
              'tipoIntegracao' => 'Api',
              'dataPrevista' => '2020-12-16',
              'cliente' => {
                'id' => '190',
                'nome' => 'Nome',
                'cnpj' => '000.000.000-08',
                'ie' => nil,
                'rg' => '',
                'endereco' => 'Rua 1',
                'numero' => '2',
                'complemento' => '3',
                'cidade' => 'Cidade',
                'bairro' => 'Bairro',
                'cep' => '00.000-000',
                'uf' => 'ES',
                'email' => 'email@example.com',
                'celular' => '11 111111111',
                'fone' => '(11) 11111-1111'
              },
              'nota' => {
                'serie' => '3',
                'numero' => '000011',
                'dataEmissao' => '2020-12-14 09:49:02',
                'situacao' => '7',
                'valorNota' => '101.24',
                'chaveAcesso' => '35201224027789000213550030000000111568817616'
              },
              'transporte' => {
                'enderecoEntrega' => {
                  'nome' => 'Nome',
                  'endereco' => 'Rua 1',
                  'numero' => '2',
                  'complemento' => '3',
                  'cidade' => 'Cidade',
                  'bairro' => 'Bairro',
                  'cep' => '00.000-000',
                  'uf' => 'ES'
                },
                'volumes' => [
                  {
                    'volume' => {
                      'id' => '3',
                      'idServico' => '34',
                      'idOrigem' => '345',
                      'servico' => 'SEDEX CONTRATO AG',
                      'codigoServico' => '03456',
                      'codigoRastreamento' => 'AB12345678',
                      'valorFretePrevisto' => '13.43',
                      'remessa' => {
                        'numero' => '12321313',
                        'dataCriacao' => '2020-12-21'
                      },
                      'dataSaida' => '2020-12-20',
                      'prazoEntregaPrevisto' => '1',
                      'valorDeclarado' => '0.00',
                      'avisoRecebimento' => false,
                      'maoPropria' => false,
                      'dimensoes' => {
                        'peso' => '1.700',
                        'altura' => '0',
                        'largura' => '0',
                        'comprimento' => '0',
                        'diametro' => '0'
                      },
                      'urlRastreamento' => 'www2.correios.com.br'
                    }
                  }
                ],
                'servico_correios' => 'SEDEX CONTRATO AG'
              },
              'itens' => [
                {
                  'item' => {
                    'codigo' => '1',
                    'descricao' => 'PRODUTO',
                    'quantidade' => '2.0000',
                    'valorunidade' => '41.0000000000',
                    'precocusto' => '22.4400000000',
                    'descontoItem' => '0.00',
                    'un' => 'UN',
                    'pesoBruto' => '1.02000',
                    'largura' => '168',
                    'altura' => '241',
                    'profundidade' => '89',
                    'descricaoDetalhada' => '',
                    'unidadeMedida' => 'm',
                    'gtin' => '12314324343'
                  }
                }
              ],
              'parcelas' => [
                {
                  'parcela' => {
                    'idLancamento' => '0',
                    'valor' => '96.60',
                    'dataVencimento' => '2020-12-26 00:00:00',
                    'obs' => '',
                    'destino' => 1,
                    'forma_pagamento' => {
                      'id' => '0',
                      'descricao' => 'Dinheiro',
                      'codigoFiscal' => '1'
                    }
                  }
                }
              ],
              'codigosRastreamento' => {
                'codigoRastreamento' => 'AB12345678'
              }
            }
          }
        ]
      }
    }
  end
  let(:status) { 'Atendido' }

  before do
    stub_const("#{Vnda::Hub}::HUB_SCHEME", 'https')
    stub_const("#{Vnda::Hub}::HUB_HOST", 'hub.vnda.com.br')
    stub_const("#{Vnda::Hub}::HUB_TOKEN", 'hub_token')

    shop.trackings.create!(code: 'AB123456789BR', package: 'ABCDE12345-01')

    stub_request(:get, 'https://hub.vnda.com.br/api/orders/ABCDE12345')
      .with(
        headers:
        {
          'Accept' => 'application/json',
          'Authorization' => 'Token token="hub_token"',
          'Content-Type' => 'application/json',
          'X-Host' => 'shop1.vnda.com.br',
          'User-Agent' => 'tracker/dev'
        }
      )
      .to_return(
        status: 200,
        body: {
          'code': 'ABCDE12345',
          'remote_code': '9988',
          'integrated': true
        }.to_json
      )
  end

  describe '#status' do
    context 'when order was delivered' do
      it 'returns order status' do
        stub_request(:get, url)
          .to_return(status: 200, body: response_with_order.to_json)

        expect(bling.status('AB123456789BR')).to eq(
          date: '2020-12-13'.to_datetime,
          status: 'delivered',
          message: 'Atendido'
        )
      end
    end

    context 'when order is in transit' do
      let(:status) { 'Em andamento' }

      it 'returns order status' do
        stub_request(:get, url)
          .to_return(status: 200, body: response_with_order.to_json)

        expect(bling.status('AB123456789BR')).to eq(
          date: '2020-12-13'.to_datetime,
          status: 'in_transit',
          message: 'Em andamento'
        )
      end
    end

    context 'with other status' do
      let(:status) { 'Outro status' }

      it 'returns order status' do
        stub_request(:get, url)
          .to_return(status: 200, body: response_with_order.to_json)

        expect(bling.status('AB123456789BR')).to eq(
          date: '2020-12-13'.to_datetime,
          status: 'pending',
          message: 'Outro status'
        )
      end
    end

    context 'when tracking code not found' do
      it 'raises error' do
        expect { bling.status('AB123456780BR') } .to raise_error(
          Bling::NotFound,
          'Tracking not found'
        )
      end
    end

    context 'with error' do
      it 'returns pending when does not have events' do
        stub_request(:get, url)
          .to_return(status: 200, body: response_with_error.to_json)

        expect(bling.status('AB123456789BR')).to eq(
          date: nil,
          status: 'pending',
          message: nil
        )
      end
    end

    context 'with HTTP error' do
      before do
        stub_request(:get, url).to_return(status: 500)
      end

      it 'returns pending' do
        expect(bling.status('AB123456789BR')).to eq(
          date: nil,
          status: 'pending',
          message: nil
        )
      end
    end

    context 'with generic Excon error' do
      before do
        stub_request(:get, url).to_raise(Excon::Error)
      end

      it 'returns pending' do
        expect(bling.status('AB123456789BR')).to eq(
          date: nil,
          status: 'pending',
          message: nil
        )
      end
    end

    context 'without remote code on hub' do
      before do
        stub_request(:get, 'https://hub.vnda.com.br/api/orders/ABCDE12345')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'Authorization' => 'Token token="hub_token"',
              'Content-Type' => 'application/json',
              'X-Host' => 'shop1.vnda.com.br',
              'User-Agent' => 'tracker/dev'
            }
          )
          .to_return(
            status: 200,
            body: {
              'code': 'ABCDE12345',
              'remote_code': nil,
              'integrated': true
            }.to_json
          )
      end

      it 'raises error' do
        expect { bling.status('AB123456789BR') } .to raise_error(
          Bling::OrderNumberError,
          'Remote order number is mandatory'
        )
      end
    end

    context 'with HTTP Status error on hub request' do
      before do
        stub_request(:get, 'https://hub.vnda.com.br/api/orders/ABCDE12345')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'Authorization' => 'Token token="hub_token"',
              'Content-Type' => 'application/json',
              'X-Host' => 'shop1.vnda.com.br',
              'User-Agent' => 'tracker/dev'
            }
          )
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises error' do
        expect { bling.status('AB123456789BR') } .to raise_error(
          Vnda::Hub::HubResponseError,
          'Internal Server Error'
        )
      end
    end

    context 'with generic Excon error' do
      let(:previous_integration_response) { {} }

      before do
        stub_request(:get, 'https://hub.vnda.com.br/api/orders/ABCDE12345')
          .with(
            headers:
            {
              'Accept' => 'application/json',
              'Authorization' => 'Token token="hub_token"',
              'Content-Type' => 'application/json',
              'X-Host' => 'shop1.vnda.com.br',
              'User-Agent' => 'tracker/dev'
            }
          )
          .to_raise(Excon::Error.new('Generic error message'))
      end

      it 'raises error' do
        expect { bling.status('AB123456789BR') } .to raise_error(
          Vnda::Hub::HubResponseError,
          'Generic error message'
        )
      end
    end
  end

  describe '#events' do
    before do
      stub_request(:get, url)
        .to_return(status: 200, body: response_with_order.to_json)
    end

    it 'returns order status' do
      expect(bling.events('AB123456789BR')).to eq(
        [
          {
            date: '2020-12-13'.to_datetime,
            status: 'delivered',
            message: 'Atendido'
          }
        ]
      )
    end
  end

  describe '#last_response' do
    before do
      stub_request(:get, url)
        .to_return(status: 200, body: response_with_order.to_json)

      bling.events('AB123456789BR')
    end

    it 'returns the integration response' do
      expect(bling.last_response).to eq(response_with_order.to_json)
    end
  end

  describe '#validate_tracking_code' do
    context 'when shop is nil' do
      it 'returns false' do
        expect(
          described_class.validate_tracking_code(nil, 'AB123456789BR')
        ).to eq(false)
      end
    end

    context 'when bling was disabled' do
      it 'returns false' do
        expect(
          described_class.validate_tracking_code(shop, 'AB123456789BR')
        ).to eq(false)
      end
    end

    context 'when bling was enabled' do
      before do
        shop.bling_enabled = true
        shop.save
      end

      it 'returns true' do
        expect(
          described_class.validate_tracking_code(shop, 'AB123456789BR')
        ).to eq(true)
      end
    end
  end
end
