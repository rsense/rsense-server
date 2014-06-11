require "pathname"
require "rsense-core"
require_relative "./listeners/find_definition_event_listener"
require_relative "./listeners/where_event_listener"
require_relative "./command/special_meth"
require_relative "./command/type_inference_method"

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
  LoadResult = Java::org.cx4a.rsense::LoadResult
  CompletionCandidate = Struct.new(
      :completion,
      :qualified_name,
      :base_name,
      :kind
    )

  attr_accessor :context, :options, :parser, :projects, :sandbox, :definitionFinder, :whereListener, :type_inference_method, :require_method, :require_next_method, :result, :graph, :project, :errors, :placeholders

  def initialize(options)
    @context = Rsense::Server::Context.new
    @context.loadPathLevel = 0
    @options = options
    @errors = []
    @placeholders = []

    @type_inference_method = Rsense::Server::Command::TypeInferenceMethod.new()

    @require_method = Rsense::Server::Command::SpecialMeth.new() do |runtime, receivers, args, blcck, result|
      if args
        feature = Java::org.cx4a.rsense.typing.vertex::Vertex.getString(args[0])
        if feature
          rrequire(@context.project, feature, "UTF-8", @context.loadPathLevel + 1)
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

  def rload(project, file, encoding, prep)
    file = Pathname.new(file)
    return LoadResult.alreadyLoaded() if project.loaded?(file)
    return if file.extname =~ /(\.so|\.dylib|\.dll|\.java|\.class|\.c$|\.h$|\.m$|\.js|\.html|\.css)/
    project.loaded << file
    oldmain = @context.main

    if prep
      prepare(project)
    else
      @context.main = false
    end

    begin
      ast = @parser.parse_string(file.read, file.to_s)
      project.graph.load(ast)
      result = LoadResult.new
      result.setAST(ast)
      result
    rescue Java::OrgJrubyparserLexer::SyntaxException => e
      @errors << e
    end
  end

  def rrequire(project, feature, encoding, loadPathLevel=0)

    lplevel = @context.loadPathLevel
    @context.loadPathLevel = loadPathLevel
    if lplevel > 1
      @placeholders << [project, feature, encoding]
    end
    return LoadResult.alreadyLoaded() if project.loaded?(feature)


    stubs = stub_matches(project, feature)
    stubs.each do |stub|
      rload(project, Pathname.new(stub), encoding, false)
    end

    lpmatches = load_path_matches(project, feature)
    lpmatches.each do |lp|
      rload(project, lp, encoding, false)
    end

    unless lpmatches
      dependencies = project.dependencies
      dpmatches = dependency_matches(dependencies, feature)
      dpmatches.each do |dp|
        rload(project, dp, encoding, false)
      end
    end

    unless lpmatches || dpmatches
      dep_paths = dependency_paths(dependencies)
      gem_path = project.gem_path.map {|gp| Pathname.new(gp) }

      checked = deep_check(gem_path, dep_paths, feature)
      checked.each do |cp|
        rload(project, cp, encoding, false)
      end
    end
    @context.loadPathLevel = lplevel
  end

  def load_builtin(project)
    builtin = builtin_path(project)
    rload(project, builtin, "UTF-8", false)
  end

  def builtin_path(project)
    Pathname.new(project.stubs.select { |stub| stub.match(/builtin/)}.first)
  end

  def stub_matches(project, feature)
    project.stubs.select { |stub| stub.to_s =~ /#{feature}/ }
  end

  def dependency_paths(dependencies)
    dependencies.map { |d| Pathname.new(d.path.first).parent }.flatten
  end

  def dependency_matches(dependencies, feature)
    dmatch = dependencies.select { |d| d.name =~ /#{feature}/ }
    if dmatch
      dmatch.map { |dm| Pathname.new(dm.path.first) unless dm.path.first == nil }.compact
    end
  end

  def load_path_matches(project, feature)
    load_path = project.load_path
    load_path.compact.map do |lp|
      Dir.glob(Pathname.new(lp).join("**/*#{feature}*"))
    end.flatten.compact.reject {|f| File.directory?(f) }
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

  def code_completion(file, location, code_str="")
    if code_str.empty?
      code = Rsense::Server::Code.new(Pathname.new(file).read)
    else
      code = Rsense::Server::Code.new(code_str)
    end

    begin
      source = code.inject_inference_marker(location)
      ast = @parser.parse_string(source, file.to_s)
      @project.graph.load(ast)
      result = Java::org.cx4a.rsense::CodeCompletionResult.new
      result.setAST(ast)
    rescue Java::OrgJrubyparserLexer::SyntaxException => e
      @errors << e
    end

    candidates = []
    @receivers = []
    @context.typeSet.each do |receiver|
      @receivers << receiver
      ruby_class = receiver.getMetaClass
      ruby_class.getMethods(true).each do |name|
        rmethod = ruby_class.searchMethod(name)
        candidates << CompletionCandidate.new(name, rmethod.toString(), rmethod.getModule().getMethodPath(nil), method_kind)
      end
      if receiver.to_java_object.java_kind_of?(Java::org.cx4a.rsense.ruby::RubyModule)
        rmodule = receiver
        rmodule.getConstants(true).each do |name|
          direct_module = rmodule.getConstantModule(name)
          constant = direct_module.getConstant(name)
          base_name = direct_module.toString()
          qname = "#{base_name}::#{name}"
          kind = kind_check(constant)
          candidates << CompletionCandidate.new(name, qname, base_name, kind)
        end
      end
    end
    candidates
  end

  def method_kind
    Java::org.cx4a.rsense::CodeCompletionResult::CompletionCandidate::Kind::METHOD
  end

  def kind_check(constant)
    if constant.class == Java::org.cx4a.rsense.ruby::RubyClass
      Java::org.cx4a.rsense::CodeCompletionResult::CompletionCandidate::Kind::CLASS
    elsif constant.class == Java::org.cx4a.rsense.ruby::RubyModule
      Java::org.cx4a.rsense::CodeCompletionResult::CompletionCandidate::Kind::MODULE
    else
      Java::org.cx4a.rsense::CodeCompletionResult::CompletionCandidate::Kind::CONSTANT
    end
  end

  def prepare(project)
    @context.project = project
    @context.typeSet = Java::org.cx4a.rsense.typing::TypeSet.new
    @context.main = true
    @type_inference_method.context = @context
    @graph = project.graph
    @graph.addSpecialMethod(Rsense::Server::Command::TYPE_INFERENCE_METHOD_NAME, @type_inference_method)
    @graph.addSpecialMethod("require", @require_method)
    @graph.addSpecialMethod("require_next", @require_next_method)
    load_builtin(project)
  end

  def clear
    @parser = Rsense::Server::Parser.new
    @context.clear()
    @projects = {}
    @sandbox = Rsense::Server::Project.new("(sandbox)", Pathname.new("."))
    @definitionFinder = Rsense::Server::Listeners::FindDefinitionEventListener.new(@context)
    @whereListener = Rsense::Server::Listeners::WhereEventListener.new(@context)
    open_project(@sandbox)
    prepare_project()
  end

  def prepare_project()
    if @options.name
      name = @roptions.name
    else
      name = "(sandbox)"
    end
    file = @options.project_path
    @project = Rsense::Server::Project.new(name, file)
    prepare(@project)
  end

end
