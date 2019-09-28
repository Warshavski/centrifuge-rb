# frozen_string_literal: true

require 'uri'

require 'rubycent/request'

module Rubycent
  # Rubycent::Query
  #
  #   Centrifugo API request configuration and execution
  #
  class Query
    attr_reader :client

    # @param client [Rubycent::Client]
    #   Rubycent client that contains all the configuration
    #
    def initialize(client)
      @client = client
    end

    # Perform centrifugo API call
    #
    # @param method [String]
    #   Centrifugo command, represents centrifugo actions such as 'publish', 'broadcast', e.t.c.
    #
    # @param data [Hash]
    #   Any data that will be sent as command parameters
    #
    # @return [Hash] Parser request responce
    #
    # @raise [Rubycent::Error, Rubycent::NetworkError, Rubycent::RequestError, Rubycent::ResponseError]
    #
    def execute(method, data)
      body = dump_body(method, data)

      params = {
        timeout: client.timeout,
        open_timeout: client.open_timeout
      }

      headers = build_headers(client.api_key)
      endpoint = build_endpoint(client.host, client.port, client.scheme.to_s)

      Rubycent::Request.new(endpoint, params, body, headers).post
    end

    private

    def dump_body(method, params)
      MultiJson.dump(method: method, params: params)
    end

    def build_endpoint(host, port, scheme)
      ::URI::Generic.build(scheme: scheme, host: host, port: port, path: '/api').to_s
    end

    def build_headers(api_key)
      {
        'Content-Type' => 'application/json',
        'Authorization' => "apikey #{api_key}"
      }
    end
  end
end
