require "rsense/server"
require "rsense/server/config"
require "optparse"

SOCKET_PATH = '127.0.0.1:'
DEFAULT_PORT = 47367

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: rsense start [options]"

  opts.on("-pp", "--path PATH", "project path") do |path|
    options[:path] = path
  end

  opts.on("-p", "--port PORT", "Port") do |port|
    options[:port] = port
  end
end.parse!

def config(options)
  if options[:path]
    path = Pathname.new(options[:path]).expand_path
  end
  conf = Rsense::Server::Config.new

  if path && path.exist?
    conf.set_up(path)
  else
    conf.set_up(Pathname.new("~").expand_path)
  end
  conf
end

def port(options)
  config = config(options)
  if options[:port] && options[:port].match(/^\d*$/)
    options[:port].to_i
  elsif config.port
    config.port
  else
    DEFAULT_PORT
  end
end

PORT = port(options)

require "puma"
require "sinatra"
require "json"

class RsenseApp < Sinatra::Base
  attr_accessor :roptions, :rcommand, :rproject

  configure { set :server, :puma }
  set :port, PORT

  def setup(jsondata)
    if @roptions && @roptions.project_path =~ /#{jsondata["project"]}/
      changed = check_options(jsondata)
      @rcommand.options = @roptions
    else
      @roptions = Rsense::Server::Options.new(jsondata)
      @rcommand = Rsense::Server::Command::Command.new(@roptions)
    end
  end

  def check_options(data)
    changed = []
    data.each do |k, v|
      unless @roptions.send k.to_sym == v
        @roptions.__send__("#{k}=", v)
        changed << k
      end
    end
    changed
  end

  def code_completion
    if @roptions.code
      candidates = @rcommand.code_completion(@roptions.file, @roptions.location, @roptions.code)
    else
      candidates = @rcommand.code_completion(@roptions.file, @roptions.location)
    end
    @rcommand.errors.each { |e| puts e }
    completions = candidates.map do |c|
      {
        name: c.completion,
        qualified_name: c.qualified_name,
        base_name: c.base_name,
        kind: c.kind.to_string
      }
    end
    { :completions => completions }
  end

  post '/' do
    content_type :json
    jsontext = request.body.read
    if jsontext
      data = JSON.parse(jsontext)
      setup(data)
      __send__(data["command"]).to_json
    else
      "No JSON was sent"
    end
  end

end

# termination signal
Signal.trap("TERM") do
  puts "TERM signal received."
  RsenseApp.stop!
end

RsenseApp.run!
