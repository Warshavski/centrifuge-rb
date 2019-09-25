# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rubycent::Query do
  let!(:client) do
    double('client', api_key: 'KEY', host: 'wathost', port: 3011, scheme: 'https', timeout: 1, open_timeout: 1)
  end

  let!(:request_params) do
    {
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "apikey KEY"
      },
      body: {
        method: 'watever',
        params: {
          content: 'wat'
        }
      }
    }
  end

  before do
    stub_request(:post, 'https://wathost:3011/api').with(request_params).to_return(body: '{}')
  end

  subject { described_class.new(client).execute('watever', content: 'wat') }

  it { is_expected.to eq({}) }
end
