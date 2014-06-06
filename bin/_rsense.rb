require "rsense/server"

require "sinatra"
require "puma"
require "json"

class RsenseApp < Sinatra::Base
  configure { set :server, :puma }

  get '/hello' do
    content_type :json
    json = request.body.read
    data = JSON.parse(json)
    { greeting: "Hello World", data: data }.to_json
  end
end

# termination signal
Signal.trap("TERM") do
  puts "TERM signal received."
  RsenseApp.stop!
end

RsenseApp.run!
