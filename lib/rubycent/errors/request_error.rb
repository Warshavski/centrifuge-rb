# frozen_string_literal: true

module Rubycent
  # Rubycent::RequestError
  #
  #   Raised when request to Centrifugo API failed in some way.
  #
  class RequestError < Error
    attr_reader :message, :status

    def initialize(message, status)
      @message = message
      @status = status

      super(message)
    end
  end
end
