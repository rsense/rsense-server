#!/usr/bin/env ruby

require "rsense/server"
require "rsense/server/config"
require "rsense/server/command/preload"
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

  opts.on("-d", "--debug", "Debug") do |debug|
    options[:debug] = true
  end
end.parse!

def config(options)
  if options[:path]
    options[:path] = path = Pathname.new(options[:path]).expand_path
  end
  conf = Rsense::Server::Config.new

  if path && path.exist?
    conf.set_up(path)
  else
    options[:path] = Pathname.new(Dir.pwd).expand_path
    conf.set_up(options[:path])
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
  attr_accessor :roptions, :rcommand, :rproject, :debug

  def debug?
    @debug
  end
end

def projman_set_up(projman, options)
  options[:path] ||= "."
  if options[:debug]
    projman.debug = true
  else
    projman.debug = false
  end
  path = Pathname.new(options[:path]).expand_path
  Rsense::Server::Command::Preload.load(projman, path)
end

PROJMAN = ProjectManager.new
projman_set_up(PROJMAN, options)

require "puma"
require "sinatra/base"
require "json"

class RsenseApp < Sinatra::Base
  attr_accessor :roptions, :rcommand, :rproject

  configure { set :server, :puma }
  set :port, PORT

  def setup(jsondata)
    if project_check?(jsondata)
      PROJMAN.roptions = Rsense::Server::Options.new(jsondata)
      PROJMAN.rcommand.options = PROJMAN.roptions
    else
      PROJMAN.roptions = Rsense::Server::Options.new(jsondata)
      PROJMAN.rcommand = Rsense::Server::Command::Command.new(PROJMAN.roptions)
    end
  end

  def project_check?(jsondata)
    PROJMAN.roptions && PROJMAN.roptions.project_path.to_s =~ /#{jsondata["project"]}/ && PROJMAN.rcommand && PROJMAN.roptions.file && PROJMAN.roptions.file.to_s =~ /#{jsondata["file"]}/
  end

  def code_completion
    if PROJMAN.roptions.code
      candidates = PROJMAN.rcommand.code_completion(PROJMAN.roptions.file, PROJMAN.roptions.location, PROJMAN.roptions.code)
    else
      candidates = PROJMAN.rcommand.code_completion(PROJMAN.roptions.file, PROJMAN.roptions.location)
    end

    if PROJMAN.debug?
      PROJMAN.rcommand.errors.each { |e| puts e }
    end

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

RsenseApp.run!
