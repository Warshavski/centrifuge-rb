# frozen_string_literal: true

module Rubycent
  # Rubycent::NetworkError
  #
  #   Raised when request to Centrifugo API failed due the network problems.
  #
  class NetworkError < Error
    attr_accessor :original_error
  end
end
