# frozen_string_literal: true

require 'rails_helper'

describe Shop, type: :model do
  subject(:shop) { Shop.create!(shop_attributes) }

  context 'without name' do
    let(:shop_attributes) do
      {
        token: 'shop1_token',
        host: 'shop1.vnda.com.br'
      }
    end

    it 'raises error' do
      expect { shop } .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'without host' do
    let(:shop_attributes) do
      {
        name: 'Shop',
        token: 'shop1_token'
      }
    end

    it 'raises error' do
      expect { shop } .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'without token' do
    let(:shop_attributes) do
      {
        name: 'Shop 1',
        host: 'shop1.vnda.com.br'
      }
    end

    it { expect(shop.token.present?).to eq(true) }
    it { expect(shop.token.size).to eq(32) }
  end

  context 'with all attributes' do
    let(:shop_attributes) do
      {
        name: 'Shop 1',
        token: 'shop1_token',
        host: 'shop1.vnda.com.br'
      }
    end

    it { expect(shop.name).to eq('Shop 1') }
    it { expect(shop.token).to eq('shop1_token') }
    it { expect(shop.slug).to eq('shop-1') }
    it { expect(shop.host).to eq('shop1.vnda.com.br') }
  end
end
