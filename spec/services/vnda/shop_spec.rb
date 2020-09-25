# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vnda::Shop do
  subject(:settings) { described_class.new(shop) }

  let(:shop) do
    Shop.create!(
      name: 'Shop 1',
      token: 'shop1_token',
      host: 'shop1.vnda.com.br',
      melhor_envio_enabled: true,
      melhor_envio_environment: 'sandbox'
    )
  end

  before do
    stub_request(:get, 'http://shop1.vnda.com.br/api/v2/shop')
      .to_return(
        status: 200,
        body: {
          settings: {
            melhor_envio_access_token: '123123'
          }
        }.to_json
      )
  end

  describe '#read' do
    it 'returns settings' do
      expect(settings.read).to eq('melhor_envio_access_token' => '123123')
    end
  end
end
