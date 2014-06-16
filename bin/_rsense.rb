require "rsense/server"
require "rsense/server/config"
require "optparse"
require "awesome_print"

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

class ProjectManager
  attr_accessor :roptions, :rcommand, :rproject
end

PROJMAN = ProjectManager.new

require "puma"
require "sinatra"
require "json"

class RsenseApp < Sinatra::Base
  attr_accessor :roptions, :rcommand, :rproject

  configure { set :server, :puma }
  set :port, PORT

  def setup(jsondata)
    if PROJMAN.roptions && PROJMAN.roptions.project_path.to_s =~ /#{jsondata["project"]}/ && PROJMAN.rcommand
      PROJMAN.roptions = Rsense::Server::Options.new(jsondata)
      PROJMAN.rcommand.options = PROJMAN.roptions
    else
      PROJMAN.roptions = Rsense::Server::Options.new(jsondata)
      PROJMAN.rcommand = Rsense::Server::Command::Command.new(PROJMAN.roptions)
    end
  end

  def code_completion
    if PROJMAN.roptions.code
      candidates = PROJMAN.rcommand.code_completion(PROJMAN.roptions.file, PROJMAN.roptions.location, PROJMAN.roptions.code)
    else
      candidates = PROJMAN.rcommand.code_completion(PROJMAN.roptions.file, PROJMAN.roptions.location)
    end
    PROJMAN.rcommand.errors.each { |e| puts e }
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

  def add_deps
    Thread.new do
      if PROJMAN.rcommand.placeholders.first
        proj, feat = PROJMAN.rcommand.placeholders.shift
        puts "Add deps: "
        puts feat
        PROJMAN.rcommand.rrequire(proj, feat, true, 0)
      end
    end
  end

  post '/' do
    @serving = true
    content_type :json
    jsontext = request.body.read
    if jsontext
      data = JSON.parse(jsontext)
      setup(data)
      retdata = __send__(data["command"]).to_json
    else
      retdata = "No JSON was sent"
    end
    add_deps
    @serving = false
    retdata
  end

end

# termination signal
Signal.trap("TERM") do
  puts "TERM signal received."
  RsenseApp.stop!
end

RsenseApp.run!
