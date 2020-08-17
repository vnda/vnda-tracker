# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /shops', type: :request do
  subject(:response_content) { response.body }

  before { authorize('foo', 'bar') }

  it 'returns empty list' do
    get '/shops', env: env

    expect(response_content).to include('Nenhuma loja cadastrada')
  end

  context 'with shops' do
    before do
      Shop.create!(name: 'foo', token: 'a1b2c3d4e5')
      Shop.create!(name: 'bar', token: '1a2b3c4d5e')
    end

    it 'returns a list of shops with 2 shops' do
      get '/shops', env: env

      expect(Shop.count).to eq(2)
    end

    it 'lists the first shop' do
      get '/shops', env: env

      expect(response_content).to include('a1b2c3d4e5')
    end

    it 'lists the second shop' do
      get '/shops', env: env

      expect(response_content).to include('1a2b3c4d5e')
    end
  end
end
