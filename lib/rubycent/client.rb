# frozen_string_literal: true

require 'rubycent/query'

require 'jwt'

module Rubycent
  # Rubycent::Client
  #
  #   Main object that handles configuration and requests to centrifugo API
  #
  class Client
    DEFAULT_OPTIONS = {
      scheme: 'http',
      host: 'localhost',
      port: 8000
    }.freeze

    private_constant :DEFAULT_OPTIONS

    attr_accessor :scheme, :host, :port, :secret, :api_key

    attr_accessor :timeout, :open_timeout

    # @param options [Hash] -
    #   (default: {}) Parameters to configure centrifugo client
    #
    # @option options [String] :scheme -
    #   Centrifugo address scheme
    #
    # @option options [String] :host -
    #   Centrifugo address host
    #
    # @option options [String] :port -
    #   Centrifugo address port
    #
    # @option options [String] :secret -
    #   Centrifugo secret(used to issue JWT)
    #
    # @option options [String] :api_key -
    #   Centrifugo API key(used to perform requests)
    #
    # @option options [String] :timeout -
    #   Number of seconds to wait for the connection to open.
    #
    # @option options [String] :open_timeout -
    #   Number of seconds to wait for one block to be read.
    #
    # @example Construct new client instance
    #   Rubycent::Client.new(
    #     scheme: 'http',
    #     host: 'localhost',
    #     port: '8000',
    #     secret: 'secret',
    #     api_key: 'api key',
    #     timeout: 10,
    #     open_timeout: 15
    #   )
    #
    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)

      @scheme, @host, @port, @secret, @api_key = options.values_at(
        :scheme, :host, :port, :secret, :api_key
      )

      @timeout = 5
      @open_timeout = 5
    end

    # Publish data into channel
    #
    # @param channel [String] -
    #   Name of the channel to publish
    #
    # @param data [Hash] -
    #   Data for publication in the channel
    #
    # @example Publish `content: 'hello'` into `chat` channel
    #   Rubycent::Client.new.publish('chat', content: 'hello') #=> {}
    #
    # @see (https://centrifugal.github.io/centrifugo/server/http_api/#publish)
    #
    # @raise [
    #   Rubycent::Error,
    #   Rubycent::NetworkError,
    #   Rubycent::RequestError,
    #   Rubycent::ResponseError
    # ]
    #
    # @return [Hash] - Return empty hash in case of successful publish
    #
    def publish(channel, data)
      construct_query.execute('publish', channel: channel, data: data)
    end

    # Publish data into multiple channels
    #   (Similar to `#publish` but allows to send the same data into many channels)
    #
    # @param channels [Array<String>] - Collection of channels names to publish
    # @param data [Hash] - Data for publication in the channels
    #
    # @example Broadcast `content: 'hello'` into `channel_1`, 'channel_2' channels
    #   Rubycent::Client.new.broadcast(['channel_1', 'channel_2'], content: 'hello') #=> {}
    #
    # @see (https://centrifugal.github.io/centrifugo/server/http_api/#broadcast)
    #
    # @raise [
    #   Rubycent::Error,
    #   Rubycent::NetworkError,
    #   Rubycent::RequestError,
    #   Rubycent::ResponseError
    # ]
    #
    # @return [Hash] - Return empty hash in case of successful broadcast
    #
    def broadcast(channels, data)
      construct_query.execute('broadcast', channels: channels, data: data)
    end

    # Unsubscribe user from channel
    #
    # @param channel [String] -
    #   Channel name to unsubscribe from
    #
    # @param user_id [String, Integer] -
    #   User ID you want to unsubscribe
    #
    # @example Unsubscribe user with `id = 1` from `chat` channel
    #   Rubycent::Client.new.unsubscribe('chat', 1) #=> {}
    #
    # @see (https://centrifugal.github.io/centrifugo/server/http_api/#unsubscribe)
    #
    # @raise [
    #   Rubycent::Error,
    #   Rubycent::NetworkError,
    #   Rubycent::RequestError,
    #   Rubycent::ResponseError
    # ]
    #
    # @return [Hash] - Return empty hash in case of successful unsubscribe
    #
    def unsubscribe(channel, user_id)
      construct_query.execute('unsubscribe', channel: channel, user: user_id)
    end

    # Disconnect user by it's ID
    #
    # @param user_id [String, Integer] -
    #   User ID you want to disconnect
    #
    # @example Disconnect user with `id = 1`
    #   Rubycent::Client.new.disconnect(1) #=> {}
    #
    # @see (https://centrifugal.github.io/centrifugo/server/http_api/#disconnect)
    #
    # @raise [
    #   Rubycent::Error,
    #   Rubycent::NetworkError,
    #   Rubycent::RequestError,
    #   Rubycent::ResponseError
    # ]
    #
    # @return [Hash] - Return empty hash in case of successful disconnect
    #
    def disconnect(user_id)
      construct_query.execute('disconnect', user: user_id)
    end

    # Get channel presence information
    #   (all clients currently subscribed on this channel)
    #
    # @param channel [String] - Name of the channel
    #
    # @example Get presence information for channel `chat`
    #   Rubycent::Client.new.presence('chat') #=> {
    #     "result" => {
    #       "presence" => {
    #         "c54313b2-0442-499a-a70c-051f8588020f" => {
    #           "client" => "c54313b2-0442-499a-a70c-051f8588020f",
    #           "user" => "42"
    #         },
    #         "adad13b1-0442-499a-a70c-051f858802da" => {
    #           "client" => "adad13b1-0442-499a-a70c-051f858802da",
    #           "user" => "42"
    #         }
    #       }
    #     }
    #   }
    #
    # @see (https://centrifugal.github.io/centrifugo/server/http_api/#presence)
    #
    # @raise [
    #   Rubycent::Error,
    #   Rubycent::NetworkError,
    #   Rubycent::RequestError,
    #   Rubycent::ResponseError
    # ]
    #
    # @return [Hash] -
    #   Return hash with information about all clients currently subscribed on this channel
    #
    def presence(channel)
      construct_query.execute('presence', channel: channel)
    end

    # Get short channel presence information
    #
    # @param channel [String] - Name of the channel
    #
    # @example Get short presence information for channel `chat`
    #   Rubycent::Client.new.presence_stats('chat') #=> {
    #     "result" => {
    #       "num_clients" => 0,
    #       "num_users" => 0
    #     }
    #   }
    #
    # @see (https://centrifugal.github.io/centrifugo/server/http_api/#presence_stats)
    #
    # @raise [
    #   Rubycent::Error,
    #   Rubycent::NetworkError,
    #   Rubycent::RequestError,
    #   Rubycent::ResponseError
    # ]
    #
    # @return [Hash] -
    #   Return hash with short presence information about channel
    #
    def presence_stats(channel)
      construct_query.execute('presence_stats', channel: channel)
    end

    # Get channel history information
    #   (list of last messages published into channel)
    #
    # @param channel [String] - Name of the channel
    #
    # @example Get history for channel `chat`
    #   Rubycent::Client.new.history('chat') #=> {
    #     "result" => {
    #       "publications" => [
    #         {
    #           "data" => {
    #             "text" => "hello"
    #           },
    #           "uid" => "BWcn14OTBrqUhTXyjNg0fg"
    #         },
    #         {
    #           "data" => {
    #             "text" => "hi!"
    #           },
    #           "uid" => "Ascn14OTBrq14OXyjNg0hg"
    #         }
    #       ]
    #     }
    #   }
    #
    # @see (https://centrifugal.github.io/centrifugo/server/http_api/#history)
    #
    # @raise [
    #   Rubycent::Error,
    #   Rubycent::NetworkError,
    #   Rubycent::RequestError,
    #   Rubycent::ResponseError
    # ]
    #
    # @return [Hash] -
    #   Return hash with a list of last messages published into channel
    #
    def history(channel)
      construct_query.execute('history', channel: channel)
    end

    # Get list of active(with one or more subscribers) channels.
    #
    # @example Get active channels list
    #   Rubycent::Client.new.channels #=> {
    #     "result" => {
    #       "channels" => [
    #         "chat"
    #       ]
    #     }
    #   }
    #
    # @see (https://centrifugal.github.io/centrifugo/server/http_api/#channels)
    #
    # @raise [
    #   Rubycent::Error,
    #   Rubycent::NetworkError,
    #   Rubycent::RequestError,
    #   Rubycent::ResponseError
    # ]
    #
    # @return [Hash] -
    #   Return hash with a list of active channels
    #
    def channels
      construct_query.execute('channels', {})
    end

    # Get information about running Centrifugo nodes
    #
    # @example Get running centrifugo nodes list
    #   Rubycent::Client.new.info #=> {
    #     "result" => {
    #       "nodes" => [
    #         {
    #           "name" => "Alexanders-MacBook-Pro.local_8000",
    #           "num_channels" => 0,
    #           "num_clients" => 0,
    #           "num_users" => 0,
    #           "uid" => "f844a2ed-5edf-4815-b83c-271974003db9",
    #           "uptime" => 0,
    #           "version" => ""
    #         }
    #       ]
    #     }
    #   }
    #
    # @see (https://centrifugal.github.io/centrifugo/server/http_api/#info)
    #
    # @raise [
    #   Rubycent::Error,
    #   Rubycent::NetworkError,
    #   Rubycent::RequestError,
    #   Rubycent::ResponseError
    # ]
    #
    # @return [Hash] -
    #   Return hash with a list of last messages published into channel
    #
    def info
      construct_query.execute('info', {})
    end

    # Generate connection JWT for the given user
    #
    # @param user_id [String] -
    #   Standard JWT claim which must contain an ID of current application user.
    #
    # @option subscriber [String] :channel
    #   Channel that client tries to subscribe to (string).
    #
    # @param expiration [Integer] -
    #   (default: nil) UNIX timestamp seconds when token will expire.
    #
    # @param info [Hash] -
    #   (default: {}) This claim is optional - this is additional information about
    #   client connection that can be provided for Centrifugo.
    #
    # @param algorithm [String] - The algorithm used for the cryptographic signing
    #
    # @note At moment the only supported JWT algorithm is HS256 - i.e. HMAC SHA-256.
    #   This can be extended later.
    #
    # @see (https://centrifugal.github.io/centrifugo/server/authentication/)
    #
    # @raise [Rubycent::Error]
    #
    # @return [String]
    #
    def issue_user_token(user_id, expiration = nil, info = {}, algorithm = 'HS256')
      issue_token({ 'sub' => user_id }, expiration, info, algorithm)
    end

    # Generate JWT for private channels
    #
    # @param client [String] -
    #   Client ID which wants to subscribe on channel
    #
    # @option channel [String] -
    #   Channel that client tries to subscribe to (string).
    #
    # @param expiration [Integer] -
    #   (default: nil) UNIX timestamp seconds when token will expire.
    #
    # @param info [Hash] -
    #   (default: {}) This claim is optional - this is additional information about
    #   client connection that can be provided for Centrifugo.
    #
    # @param algorithm [String] - The algorithm used for the cryptographic signing
    #
    # @note At moment the only supported JWT algorithm is HS256 - i.e. HMAC SHA-256.
    #   This can be extended later.
    #
    # @see (https://centrifugal.github.io/centrifugo/server/private_channels/)
    #
    # @raise [Rubycent::Error]
    #
    # @return [String]
    #
    def issue_channel_token(client, channel, expiration = nil, info = {}, algorithm = 'HS256')
      issue_token({ 'client' => client, 'channel' => channel }, expiration, info, algorithm)
    end

    private

    def issue_token(subscriber, expiration, info, algorithm)
      raise Error, 'Secret can not be nil' if secret.nil?

      payload = subscriber.merge('info' => info).tap do |p|
        p['exp'] = expiration if expiration
      end

      JWT.encode(payload, secret, algorithm)
    end

    def construct_query
      Query.new(self)
    end
  end
end
