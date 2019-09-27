# frozen_string_literal: true

module Rubycent
  # Rubycent::ResponseError
  #
  #   Raised when response from Centrifugo contains any error as result of API command execution.
  #
  class ResponseError < Error
    attr_reader :message, :code

    def initialize(error_data)
      @message, @code = error_data.values_at('message', 'code')

      super(@message)
    end
  end
end
