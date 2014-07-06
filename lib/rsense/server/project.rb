require_relative "./command/graph"
require_relative "./command/runtime_helper"
require "rsense-core"

module Rsense
  module Server
    class Project
      attr_accessor :name, :path, :graph, :runtime, :load_path, :gem_path, :loaded, :dependencies, :stubs

      def initialize(name, path)
        @name = name
        @path = path
        #@graph = Java::org.cx4a.rsense.typing::Graph.new
        @graph = Rsense::Server::Command::Graph.new
        @runtime = @graph.getRuntime()
        @stubs = Dir.glob(Rsense::BUILTIN.join("**/*.rb"))
        @load_path = Rsense::Server::LoadPath.paths
        unless @path == "."
          @load_path << Pathname.new(@path)
        end
        @gem_path = Rsense::Server::GemPath.paths
        @loaded = []
        @dependencies = Rsense::Server::LoadPath.dependencies(@path)
      end

      def loaded?(feature)
        @loaded.include?(feature)
      end

    end
  end
end
