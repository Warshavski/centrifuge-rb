# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rubycent::Request do
  let!(:endpoint) { 'http://localhost:3000/api' }

  let!(:params) { { timeout: 5, open_timeout: 5 } }
  let!(:body)   { { method: 'watever', params: { content: 'wat' } } }

  describe '#post' do
    subject { described_class.new(endpoint, params, body).post }

    it 'surfaces Faraday::ConnectionFailed exception as a Rubycent::NetworkError' do
      exception = Faraday::ConnectionFailed.new('not good at all')

      stub_request(:post, endpoint).to_raise(exception)

      expect { subject }.to raise_error(Rubycent::NetworkError)
    end

    it 'surfaces response with status 400 as a Rubycent::RequestError' do
      response_values = { status: 400, headers: {}, body: 'smt. goes wrong' }

      stub_request(:post, endpoint).to_return(response_values)

      expect { subject }.to raise_error(Rubycent::RequestError)
    end

    it 'surfaces response with status 401 as a Rubycent::RequestError' do
      response_values = { status: 401, headers: {}, body: 'authorization failed' }

      stub_request(:post, endpoint).to_return(response_values)

      expect { subject }.to raise_error(Rubycent::RequestError)
    end

    it 'surfaces response with status 404 as a Rubycent::RequestError' do
      response_values = { status: 401, headers: {}, body: 'resource not found' }

      stub_request(:post, endpoint).to_return(response_values)

      expect { subject }.to raise_error(Rubycent::RequestError)
    end

    it 'surfaces response with status 500 as a Rubycent::Error' do
      response_values = { status: 500, headers: {}, body: 'unknown error' }

      stub_request(:post, endpoint).to_return(response_values)

      expect { subject }.to raise_error(Rubycent::Error)
    end

    it 'surfaces response with status 200 and error section as a Rubycent::ResponseError' do
      response_values = {
        status: 200,
        headers: {},
        body: {
          error: {
            message: 'not valid',
            code: 102
          }
        }.to_json
      }

      stub_request(:post, endpoint).to_return(response_values)

      expect { subject }.to raise_error(Rubycent::ResponseError)
    end

    it 'returns request body as hash in case of the valid request' do
      response_values = { status: 200, headers: {}, body: {}.to_json }

      stub_request(:post, endpoint).to_return(response_values)

      is_expected.to eq({})
    end
  end
end
