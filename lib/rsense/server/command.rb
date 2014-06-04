require "pathname"
require "rsense-core"
require_relative "./listeners/find_definition_event_listener"
require_relative "./listeners/where_event_listener"
require_relative "./command/special_meth"

module Rsense
  module Server
    Context = Struct.new(:project, :typeSet, :main, :feature, :loadPathLevel) {
      def clear
        @project = nil
        @typeSet = nil
        @main = false
        @feature = nil
        @loadPathLevel = 0
      end
    }
    module Command
      TYPE_INFERENCE_METHOD_NAME = Rsense::CodeAssist::TYPE_INFERENCE_METHOD_NAME
      FIND_DEFINITION_METHOD_NAME_PREFIX = Rsense::CodeAssist::FIND_DEFINITION_METHOD_NAME_PREFIX
      PROJECT_CONFIG_NAME = ".rsense"
    end
  end
end

class Rsense::Server::Command::Command

  attr_accessor :context, :options, :parser, :projects, :sandbox, :definitionFinder, :whereListener, :type_inference_method, :require_method, :require_next_method, :result, :graph

  def initialize(options)
    @context = Rsense::Server::Context.new
    @options = options

    @type_inference_method = Rsense::Server::Command::SpecialMeth.new() do |runtime, receivers, args, blcck, result|
      receivers.each do |receiver|
        @context.typeSet.add(receiver)
      end
      result.setResultTypeSet(receivers)
      result.setNeverCallAgain(true)
    end

    @require_method = Rsense::Server::Command::SpecialMeth.new() do |runtime, receivers, args, blcck, result|
      if args
        feature = Java::org.cx4a.rsense.typing.vertex::Vertex.getString(args[0])
        if feature
          rrequire(@context.project, feature, "UTF-8")
        end
      end
    end

    @require_next_method = Rsense::Server::Command::SpecialMeth.new() do |runtime, receivers, args, blcck, result|
      if @context.feature
        rrequire(@context.project, @context.feature, "UTF-8", @context.loadPathLevel + 1)
      end
    end

    clear()
  end

  def rrequire(project, feature, encoding, loadPathLevel=0)
    if project.loaded?(feature)
      Java::org.cx4a.rsense::LoadResult.alreadyLoaded()
    end
    project.loaded[feature] = true

    stubs = stubs_matches(project, feature)
    stubs.each do |stub|
      rload(project, Pathname.new(stub), encoding, false)
    end

    lpmatches = load_path_matches(project, feature)
    lpmatches.each do |lp|
      rload(project, lp, encoding, false)
    end

    dependencies = project.dependencies
    dpmatches = dependency_matches(dependencies, feature)
    dpmatches.each do |dp|
      rload(project, dp, encoding, false)
    end

    unless lpmatches || dpmatches
      dep_paths = dependency_paths(dependencies)
      gem_path = project.gem_path.map {|gp| Pathname.new(gp) }

      checked = deep_check(gem_path, dep_paths, feature)
      checked.each do |cp|
        rload(project, cp, encoding, false)
      end
    end
  end

  def stub_matches(project, feature)
    Dir.glob(project.stubs.join("**/*.rb")).select { |stub| stub.to_s =~ /#{feature}/ }
  end

  def dependency_paths(dependencies)
    dependencies.map { |d| Pathname.new(d.path.first).parent }.flatten
  end

  def dependency_matches(dependencies, feature)
    dmatch = dependencies.select { |d| d.name =~ /#{feature}/ }
    if dmatch
      dmatch.map { |dm| Pathname.new(dm.path.first) }
    end
  end

  def load_path_matches(project, feature)
    load_path = project.load_path
    load_path.map do |lp|
      Dir.glob(Pathname.new(lp).join("**/*#{feature}*"))
    end.flatten.compact
  end

  def deep_check(gem_path, dep_paths, feature)
    checkpaths = gem_path + dep_paths
    checkpaths.map do |p|
      Dir.glob(Pathname.new(p).join("**/*#{feature}*"))
    end.flatten.compact
  end

  def open_project(project)
    @projects[project.name] = project
  end

  def prepare(project)
    @context.project = project
    @context.typeSet = Java::org.cx4a.rsense.typing::TypeSet.new
    @context.main = true
    @graph = project.graph
    @graph.addSpecialMethod(TYPE_INFERENCE_METHOD_NAME, @type_inference_method)
    @graph.addSpecialMethod("require", @require_method)
    @graph.addSpecialMethod("require_next", @require_next_method)
    rrequire(project, "_builtin", "UTF-8")
  end

  def clear
    @parser = Rsense::Server::Parser.new
    @context.clear()
    @projects = {}
    @sandbox = Rsense::Server::Project.new("(sandbox)", Pathname.new("."))
    @definitionFinder = Rsense::Server::Listeners::FindDefinitionEventListener.new(@context)
    @whereListener = Rsense::Server::Listeners::WhereEventListener.new(@context)
    open_project(@sandbox)
  end

end
