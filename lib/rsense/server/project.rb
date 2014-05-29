module Rsense
  module Server
    class Project
      attr_accessor :name, :path, :graph, :runtime, :load_path, :gem_path, :loaded, :dependencies

      def initialize(name, path)
        @name = name
        @path = path
        @graph = Rsense::Typing::Graph.new
        @runtime = @graph.getRuntime()
        @loadPath = Rsense::Server::LoadPath.paths
        @gemPath = Rsense::Server::GemPath.paths
        @loaded = {}
        @dependencies = Rsense::Server::LoadPath.dependencies(@path)
      end

    end
  end
end
