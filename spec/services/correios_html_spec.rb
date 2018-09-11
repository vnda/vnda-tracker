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
    'https://www2.correios.com.br/sistemas/rastreamento/resultado_semcontent.' \
    'cfm'
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
        is_expected.to eq(
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
end
