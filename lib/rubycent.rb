# frozen_string_literal: true

require 'forwardable'
require 'multi_json'

require 'rubycent/version'

require 'rubycent/client'
require 'rubycent/request'

require 'rubycent/error'
require 'rubycent/errors/network_error'
require 'rubycent/errors/request_error'
require 'rubycent/errors/response_error'

# Rubycent
#
#   Entry point and configuration definition
#
module Rubycent
  class << self
    extend Forwardable

    def_delegators :api_client, :scheme, :host, :port, :secret, :api_key
    def_delegators :api_client, :scheme=, :host=, :port=, :secret=, :api_key=

    def_delegators :api_client, :timeout=, :open_timeout=

    def_delegators :api_client,
                   :publish, :broadcast,
                   :unsubscribe, :disconnect,
                   :presence, :presence_stats,
                   :history, :channels, :info

    attr_writer :logger, :request_adapter

    def logger
      @logger ||= begin
        Logger.new($stdout).tap { |log| log.level = Logger::INFO }
      end
    end

    def request_adapter
      @request_adapter ||= Faraday.default_adapter
    end

    def api_client
      @api_client ||= Rubycent::Client.new
    end
  end
end
