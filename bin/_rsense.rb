require "rsense/server"

require "puma"
require "sinatra"
require "json"

class RsenseApp < Sinatra::Base
  configure { set :server, :puma }

  get '/hello' do
    content_type :json
    jsontext = request.body.read
    if jsontext
      data = JSON.parse(jsontext)
    else
      "No json was sent."
    end
    { greeting: "Hello World", data: data }.to_json
  end
end

# termination signal
Signal.trap("TERM") do
  puts "TERM signal received."
  RsenseApp.stop!
end

RsenseApp.run!
