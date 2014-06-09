require "filetree"
require "json"

module Rsense
  module Server

  end
end

class Rsense::Server::Config
  attr_accessor :searched, :options, :errors, :port, :ignores

  def initialize
    @searched = []
    @ignores = []
    @errors = []
  end

  def search(path_str="~")
    path = FileTree.new(path_str)
    return if @searched.include?(path)
    @searched << path
    conf = path.join(".rsense").expand_path
    unless conf.exist?
      unless path.parent == path
        conf = search(path.parent)
      end
    end
    conf
  end

  def options(config_path)
    begin
      json_str = JSON.parse(config_path.read)
    rescue JSON::ParserError => e
      @errors << e
    end
    if json_str
      @options ||= Rsense::Server::Options.new(json_str)
    else
      @options ||= Rsense::Server::Options.new({})
    end
    @options
  end

  def port
    @port ||= check_options("port")
  end

  def ignores
    if @ignores.empty?
      @ignores << check_options("ignores")
      @ignores.flatten!
    end
    @ignores
  end

  def check_options(name)
    @options.rest[name] if @options.rest.key?(name)
  end

  def set_up(path)
    conf = search(path)
    if conf
      options(conf)
    end
  end


end
