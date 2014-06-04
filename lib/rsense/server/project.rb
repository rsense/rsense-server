module Rsense
  module Server
    class Project
      attr_accessor :name, :path, :graph, :runtime, :load_path, :gem_path, :loaded, :dependencies, :stubs

      def initialize(name, path)
        @name = name
        @path = path
        @graph = Rsense::Typing::Graph.new
        @runtime = @graph.getRuntime()
        @stubs = Dir.glob(Rsense::BUILTIN.join("**/*.rb"))
        @load_path = Rsense::Server::LoadPath.paths
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
