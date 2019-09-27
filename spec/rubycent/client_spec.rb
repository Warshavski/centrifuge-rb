# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rubycent::Client do
  context 'API interaction' do
    let!(:channel) { 'chat' }

    let!(:headers) do
      {
        'Content-Type' => 'application/json',
        'Authorization' => 'apikey api_key'
      }
    end

    let!(:client) { described_class.new(api_key: 'api_key') }

    before do
      stub_request(:post, 'http://localhost:8000/api')
        .with(body: params, headers: headers)
        .to_return(status: 200, body: expected_body)
    end

    context 'empty body responses' do
      let!(:expected_body) { '{}' }

      describe '#publish' do
        let(:data) { { content: 'wat' } }

        let(:params) do
          {
            method: 'publish',
            params: { channel: channel, data: data }
          }
        end

        subject { client.publish(channel, data) }

        it { is_expected.to eq({}) }
      end

      describe '#broadcast' do
        let(:data) { { content: 'wat' } }

        let(:params) do
          {
            method: 'broadcast',
            params: { channels: [channel], data: data }
          }
        end

        subject { client.broadcast([channel], data) }

        it { is_expected.to eq({}) }
      end

      describe '#unsubscribe' do
        let(:params) do
          {
            method: 'unsubscribe',
            params: { channel: channel, user: 1 }
          }
        end

        subject { client.unsubscribe(channel, 1) }

        it { is_expected.to eq({}) }
      end

      describe '#disconnect' do
        let(:params) do
          {
            method: 'disconnect',
            params: { user: 1 }
          }
        end

        subject { client.disconnect(1) }

        it { is_expected.to eq({}) }
      end
    end

    context 'presence' do
      let!(:expected_body) do
        '{
        "result": {
          "presence": {
            "c54313b2-0442-499a-a70c-051f8588020f": {
              "client": "c54313b2-0442-499a-a70c-051f8588020f",
              "user": "42"
            }
          }
        }
      }'
      end

      describe '#presence' do
        let(:params) do
          {
            method: 'presence',
            params: { channel: channel }
          }
        end

        subject { client.presence(channel) }

        it 'returns hash with channel presence information' do
          expected_hash = {
            'result' => {
              'presence' => {
                'c54313b2-0442-499a-a70c-051f8588020f' => {
                  'client' => 'c54313b2-0442-499a-a70c-051f8588020f',
                  'user' => '42'
                }
              }
            }
          }

          is_expected.to eq(expected_hash)
        end
      end
    end

    context 'presence_stats' do
      let!(:expected_body) do
        '{
        "result": {
          "num_clients": 0,
          "num_users": 0
        }
      }'
      end

      describe '#presence_stats' do
        let(:params) do
          {
            method: 'presence_stats',
            params: { channel: channel }
          }
        end

        subject { client.presence_stats(channel) }

        it 'returns hash with channel presence_stats information' do
          expected_hash = {
            'result' => {
              'num_clients' => 0,
              'num_users' => 0
            }
          }

          is_expected.to eq(expected_hash)
        end
      end
    end

    context 'history' do
      let!(:expected_body) do
        '{
        "result": {
          "publications": [
            {
              "data": {
                "text": "hello"
              },
              "uid": "BWcn14OTBrqUhTXyjNg0fg"
            }
          ]
        }
      }'
      end

      describe '#history' do
        let(:params) do
          {
            method: 'history',
            params: { channel: channel }
          }
        end

        subject { client.history(channel) }

        it 'returns channel history information' do
          expected_hash = {
            'result' => {
              'publications' => [
                {
                  'data' => {
                    'text' => 'hello'
                  },
                  'uid' => 'BWcn14OTBrqUhTXyjNg0fg'
                }
              ]
            }
          }

          is_expected.to eq(expected_hash)
        end
      end
    end

    context 'channels' do
      let!(:expected_body) do
        '{
          "result": {
            "channels": [
              "chat"
            ]
          }
       }'
      end

      describe '#channels' do
        let(:params) do
          {
            method: 'channels',
            params: {}
          }
        end

        subject { client.channels }

        it 'returns channel history information' do
          expected_hash = {
            'result' => {
              'channels' => [
                'chat'
              ]
            }
          }

          is_expected.to eq(expected_hash)
        end
      end
    end

    context 'info' do
      let!(:expected_body) do
        '{
        "result": {
          "nodes": [
            {
              "name": "Alexanders-MacBook-Pro.local_8000",
              "num_channels": 0,
              "num_clients": 0,
              "num_users": 0,
              "uid": "f844a2ed-5edf-4815-b83c-271974003db9",
              "uptime": 0,
              "version": ""
            }
          ]
        }
      }'
      end

      describe '#info' do
        let(:params) do
          {
            method: 'info',
            params: {}
          }
        end

        subject { client.info }

        it 'returns channel history information' do
          expected_hash = {
            'result' => {
              'nodes' => [
                {
                  'name' => 'Alexanders-MacBook-Pro.local_8000',
                  'num_channels' => 0,
                  'num_clients' => 0,
                  'num_users' => 0,
                  'uid' => 'f844a2ed-5edf-4815-b83c-271974003db9',
                  'uptime' => 0,
                  'version' => ''
                }
              ]
            }
          }

          is_expected.to eq(expected_hash)
        end
      end
    end
  end

  context 'jwt' do
    describe '#issue_user_token' do
      before do
        allow(JWT).to receive(:encode).with(payload, 'secret', 'HS256').and_return('token')
      end

      context 'without expiration' do
        let!(:payload) { { 'sub' => 1, 'info' => 'wat' } }

        subject { described_class.new(secret: 'secret').issue_user_token(1, nil, 'wat') }

        it { is_expected.to eq('token') }
      end

      context 'with expiration' do
        let!(:payload) { { 'sub' => 1, 'info' => 'wat', 'exp' => 123 } }

        subject { described_class.new(secret: 'secret').issue_user_token(1, 123, 'wat') }

        it { is_expected.to eq('token') }
      end

      context 'empty secret' do
        let!(:payload) { { 'sub' => 1 } }

        subject { described_class.new.issue_user_token(1) }

        it { expect { subject }.to raise_error(Rubycent::Error) }
      end
    end

    describe '#issue_channel_token' do
      before do
        allow(JWT).to receive(:encode).with(payload, 'secret', 'HS256').and_return('token')
      end

      context 'without expiration' do
        let!(:payload) { { 'client' => 'client', 'channel' => 'channel', 'info' => 'wat' } }

        subject { described_class.new(secret: 'secret').issue_channel_token('client', 'channel', nil, 'wat') }

        it { is_expected.to eq('token') }
      end

      context 'with expiration' do
        let!(:payload) { { 'client' => 'client', 'channel' => 'channel', 'info' => 'wat', 'exp' => 123 } }

        subject { described_class.new(secret: 'secret').issue_channel_token('client', 'channel', 123, 'wat') }

        it { is_expected.to eq('token') }
      end

      context 'empty secret' do
        let!(:payload) { { 'client' => 'client', 'channel' => 'channel' } }

        subject { described_class.new.issue_channel_token('client', 'channel') }

        it { expect { subject }.to raise_error(Rubycent::Error) }
      end
    end
  end
end
