# frozen_string_literal: true

require 'faraday'

module Rubycent
  # Rubycent::Request
  #
  #   Holds request call and response handling logic
  #
  class Request
    attr_accessor :endpoint, :params, :body, :headers

    # @param endpoint [String] Centrifugo API endpoint
    #
    # @param params [Hash] Additional params to configure request.
    #
    # @option params [Integer] :timeout
    #   Number of seconds to wait for the connection to open.
    #
    # @option params [Integer] :open_timeout
    #   Number of seconds to wait for one block to be read.
    #
    # @param body [String]
    #   (default: nil) JSON string representing request parameters.
    #
    # @param headers [Hash]
    #   (default: {}) Additional HTTP headers(such as Content-Type and Authorization).
    #
    def initialize(endpoint, params, body = nil, headers = {})
      @endpoint = endpoint
      @params = params
      @body = body
      @headers = headers
    end

    # Perform POST request to centrifugo API
    #
    # @raise [Rubycent::Error, Rubycent::NetworkError, Rubycent::RequestError, Rubycent::ResponseError]
    #
    # @return [Hash] Parsed response body
    #
    def post
      response = rest_client.post(@endpoint) do |request|
        configure_request(request: request, body: body, headers: headers)
      end

      handle_response(response)
    rescue Faraday::ConnectionFailed => e
      handle_error(e)
    end

    private

    def rest_client
      Faraday.new do |faraday|
        faraday.adapter(Rubycent.request_adapter)
        faraday.headers = @headers
      end
    end

    def configure_request(request: nil, headers: nil, body: nil)
      return if request.nil?

      request.headers.merge!(headers) if headers
      request.body = body if body

      request.options.timeout = @params[:timeout]
      request.options.open_timeout = @params[:open_timeout]
    end

    def handle_response(response)
      response.status == 200 ? parse_response(response) : raise_error(response)
    end

    def parse_response(response)
      MultiJson.load(response.body).tap do |data|
        raise ResponseError, data['error'] if data.key?('error')
      end
    end

    def raise_error(response)
      status_code = response.status
      body = response.body

      message = resolve_error_message(status_code, body)

      case status_code
      when 400..404
        raise RequestError.new(message, status_code)
      else
        raise Error, message
      end
    end

    def resolve_error_message(status, additional_info = nil)
      error_messages = {
        400 => "Bad request: #{additional_info}",
        401 => 'Invalid API key',
        404 => 'Route not found'
      }

      error_messages.fetch(status) do
        "Status: #{status}. Unknown error: #{additional_info}"
      end
    end

    def handle_error(error)
      message = "#{error.message} (#{error.class})"

      wrapper = NetworkError.new(message).tap do |w|
        w.original_error = error
      end

      raise wrapper
    end
  end
end
