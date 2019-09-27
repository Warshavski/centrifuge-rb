# Rubycent

[![Build Status](https://travis-ci.com/Warshavski/rubycent.svg?branch=master)](https://travis-ci.com/Warshavski/rubycent)

Ruby tools to communicate with [Centrifugo v2 HTTP API.](https://centrifugal.github.io/centrifugo/server/http_api/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubycent'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rubycent

## Usage

The top-level object needed for gem functionality is the Rubycent::Client object. 
A client requires your Centrifugo API key to execute all requests and Centrifugo secret to issue JWT(user and private channels)

To use a client you need first configure it by setting Centrifugo API address.

```ruby
client = Rubycent::Client.new(scheme: :http, host: :localhost, port: 80, api_key: 'key', secret: 'secret')
```

or 

```ruby
Rubycent.scheme = :http
Rubycent.host = 'localhost'
Rubycent.port = 8000
Rubycent.secret = 'secret'
Rubycent.api_key = 'key'
```

This gem use [Faraday](https://github.com/lostisland/faraday) in this case you can switch request adapters.

Request configuration:

```ruby
Rubycent.request_adapter = :httpclient
Rubycent.timeout = 10 # Number of seconds to wait for the connection to open.
Rubycent.open_timeout = 10 # Number of seconds to wait for one block to be read.
```

### Publish

Allows to send data into channel. Receives channel name and data to post

Example:

```ruby
# Publish `content: 'hello'` to channel `chat`
# 
Rubycent.publish('chat', content: 'hello') # => {}
```

### Broadcast

Similar to publish but allows to send the same data into many channels.

Example:

```ruby
# Publish { content: 'hello' } to channels 'channel_1', 'channel_2'
# 
Rubycent.broadcast(%w(channel_1 channel_2), content: 'hello') # => {}
```

### Unsubscribe

Allows to unsubscribe user from channel. Receives to arguments: channel and user (user ID you want to unsubscribe)

Example:

```ruby
# Unsubscribe user with id = 1 from 'chat' channel
# 
Rubycent.unsubscribe('chat', 1) # => {}
```

### Disconnect

Allows to disconnect user by it's ID. Receives user ID as an argument.

Example: 

```ruby
# Disconnect user with `id = 1`
# 
Rubycent.disconnect(1) # => {}
```

### Presence

Allows to get channel presence information(all clients currently subscribed on this channel). Receives channel name as an argument.

Example:

```ruby
# Get presence information for channel 'chat'
# 
Rubycent.presence('chat') 

# {
#   'result' => {
#     'presence' => {
#       'c54313b2-0442-499a-a70c-051f8588020f' => {
#         'client' => 'c54313b2-0442-499a-a70c-051f8588020f',
#         'user' => '42'
#       },
#       'adad13b1-0442-499a-a70c-051f858802da' => {
#         'client' => 'adad13b1-0442-499a-a70c-051f858802da',
#         'user' => '42'
#       }
#     }
#   }
# }
``` 

### Presence stats

Allows to get short channel presence information. Receives channel name as an argument.

Example:

```ruby
# Get short presence information for channel 'chat'
#
Rubycent.presence_stats('chat')

# {
#   "result" => {
#     "num_clients" => 0,
#     "num_users" => 0
#   }
# }
```

### History

Allows to get channel history information (list of last messages published into channel). Receives channel name as an argument.

Example:

```ruby
# Get history for channel 'chat'
#
Rubycent.history('chat') 

# {
#   'result' => {
#     'publications' => [
#       {
#         'data' => {
#           'text' => 'hello'
#         },
#         'uid' => 'BWcn14OTBrqUhTXyjNg0fg'
#       },
#       {
#         'data' => {
#           'text' => 'hi!'
#         },
#         'uid' => 'Ascn14OTBrq14OXyjNg0hg'
#       }
#     ]
#   }
# }
```

### Channels

Allows to get list of active(with one or more subscribers) channels.

Example:

```ruby
# Get active channels list
# 
Rubycent.channels

# {
#   'result' => {
#     'channels' => [
#       'chat'
#     ]
#   }
# }
```

### Info

Allows to get information about running Centrifugo nodes.

Example:

```ruby
# Get running centrifugo nodes list
# 
Rubycent.info

# {
#   'result' => {
#     'nodes' => [
#       {
#         'name' => 'Alexanders-MacBook-Pro.local_8000',
#         'num_channels' => 0,
#         'num_clients' => 0,
#         'num_users' => 0,
#         'uid' => 'f844a2ed-5edf-4815-b83c-271974003db9',
#         'uptime' => 0,
#         'version' => ''
#       }
#     ]
#   }
# }
```

### User JWT

When connecting to Centrifugo client must provide connection JWT token with several predefined credential claims.

#### Claims

##### sub
This is a standard JWT claim which must contain an ID of current application user (as string).

If your user is not currently authenticated in your application but you want to let him connect to Centrifugo anyway you can use empty string as user ID in this sub claim. 
This is called anonymous access. 
In this case anonymous option must be enabled in Centrifugo configuration for channels that client will subscribe to.

##### exp
This is standard JWT claim a UNIX timestamp seconds when token will expire. 

If exp claim not provided then Centrifugo won’t expire any connections. 
When provided special algorithm will find connections with exp in the past and activate connection refresh mechanism. 
Refresh mechanism allows connection to survive and be prolonged. 
In case of refresh failure client connection will be eventually closed by Centrifugo and won’t be accepted until new valid and actual credentials provided in connection token.

You can use connection expiration mechanism in cases when you don’t want users of your app be subscribed on channels after being banned/deactivated in application. 
Or to protect your users from token leak (providing reasonably small time of expiration).

Choose exp value wisely, you don’t need small values because refresh mechanism will hit your application often with refresh requests. 
But setting this value too large can lead to non very fast user connection deactivation. 
This is a trade off.

Read more about connection expiration in special chapter.

##### info
This claim is optional - this is additional information about client connection that can be provided for Centrifugo. 
This information will be included in presence information, join/leave events and in channel publication message if it was published from client side.

Example: 

```ruby
Rubycent.issue_user_token('1', 3600, info: { message: 'watever' }) 

#=> "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiaW5mbyI6eyJpbmZvIjp7Im1lc3NhZ2UiOiJ3YXRldmVyIn19LCJleHAiOjM2MDB9.iflaYrNxc_qQAtj52gr1q1G80jHoCgCJ0Pz3wzeKYpU"
```

### Channel JWT

All channels starting with $ considered private. 

Private channel subscription token is also JWT (like connection token described in authentication chapter). 
But it has different claims.

#### Claims

##### client
Required. Client ID which wants to subscribe on channel (string).

Centrifugo server have own Client ID representation in UUIDv4 format. 
You have to use Client ID generated by Centrifugo server for private channel subscrition purposes. 
If you using Centrifuge-JS library - Client ID and Subscription Channels will be automaticaly added to POST request.

##### channel
Required. Channel that client tries to subscribe to (string).

##### info
Optional. Additional information for connection regarding to channel (valid JSON).

##### exp
Optional. This is standard JWT claim that allows to set private channel subscription token expiration time.

At moment if subscription token expires client connection will be closed and client will try to reconnect. 
In most cases you don’t need this and should prefer using exp of connection token to deactivate connection. 
But if you need more granular per-channel control this may fit your needs.

Once exp set in token every subscription token must be periodically refreshed.

Example:

```ruby
Rubycent.issue_channel_token('client', 'channel', 3600, info: { message: 'watever' }) 

#=> "eyJhbGciOiJIUzI1NiJ9.eyJjbGllbnQiOiJjbGllbnQiLCJjaGFubmVsIjoiY2hhbm5lbCIsImluZm8iOnsiaW5mbyI6eyJtZXNzYWdlIjoid2F0ZXZlciJ9fSwiZXhwIjozNjAwfQ.jo9WFbbrUyvZt3BtHpPA1J6WMQTuJfr6jgNn9fm0SJQ"
```

### Errors

```ruby
# Wrapper for all rubycent errors(failures).
#   
Rubycent::Error

# Raised when request to Centrifugo API failed due the network problems.
# 
Rubycent::NetworkError

# Raised when request to Centrifugo API failed in some way.
#
Rubycent::RequestError

# Raised when response from Centrifugo contains any error as result of API command execution.
# 
Rubycent::ResponseError
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/warshavski/rubycent. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rubycent project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rubycent/blob/master/CODE_OF_CONDUCT.md).
