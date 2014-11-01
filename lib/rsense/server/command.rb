require "pathname"
require "rsense-core"
require_relative "./listeners/find_definition_event_listener"
require_relative "./listeners/where_event_listener"
require_relative "./command/special_meth"
require_relative "./command/type_inference_method"
require_relative "./command/native_attr_method"
require_relative "./command/alias_native_method"
require_relative "./command/rsense_method"
require_relative "./command/preload"

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

      def clean_typeSet
        @typeSet = nil
        @typeSet = Java::org.cx4a.rsense.typing::TypeSet.new
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

  attr_accessor :context, :options, :parser, :projects, :sandbox, :definitionFinder, :whereListener, :type_inference_method, :require_method, :require_next_method, :result, :graph, :project, :errors, :placeholders, :require_relative_method, :ast

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
          rrequire(@context.project, feature, false, @context.loadPathLevel + 1)
        end
      end
    end

    @require_relative_method = Rsense::Server::Command::SpecialMeth.new() do |runtime, receivers, args, blcck, result|
      if args
        feature = Java::org.cx4a.rsense.typing.vertex::Vertex.getString(args[0])
        if feature
          files = Dir.glob(Pathname.new(args.first.node.position.file).dirname.join("#{feature}*"))
          files.each do |f|
            pth = Pathname.new(f).expand_path
            if pth.file?
              rload(project, f, "UTF-8", false)
            end
          end
        end
      end
    end

    @require_next_method = Rsense::Server::Command::SpecialMeth.new() do |runtime, receivers, args, blcck, result|
      if @context.feature
        rrequire(@context.project, @context.feature, false, @context.loadPathLevel + 1)
      end
    end

    @native_attr_method = Rsense::Server::Command::NativeAttrMethod.new()

    @alias_native_method = Rsense::Server::Command::AliasNativeMethod.new()

    clear()
  end

  def rload(project, file, encoding, prep)
    file = Pathname.new(file)
    feature = file.basename.to_s.sub(file.extname, "")
    return LoadResult.alreadyLoaded() if project.loaded?(file)
    return LoadResult.alreadyLoaded() if project.loaded?(feature)
    return if file.extname =~ /(\.so|\.dylib|\.dll|\.java|\.class|\.jar|\.c$|\.h$|\.m$|\.js|\.html|\.css)/

    project.loaded << file

    oldmain = @context.main

    if prep
      prepare(project)
    else
      @context.main = false
    end
    return if file.directory?

    source = file.read
    return unless check_shebang(source)

    begin
      @ast = @parser.parse_string(source, file.to_s)
      project.graph.load(@ast)

    rescue Java::OrgJrubyparserLexer::SyntaxException => e
      @errors << e
    rescue Java::JavaUtil::ConcurrentModificationException => e
      @errors << e
    end
  end

  def load_gem(project, source, index)
    return if index > 15
    begin
      @ast = @parser.parse_string(source.source, source.name)
      project.graph.load(@ast)
    rescue Java::OrgJrubyparserLexer::SyntaxException => e
      @errors << e
    rescue Java::JavaLang::NullPointerException => e
      @errors << e
    rescue Java::JavaUtil::ConcurrentModificationException => e
      @errors << e
    end
  end

  def check_shebang(source)
    return true unless source.match(/^#!/)
    source.match(/^(#!)(\/\w+)*\/ruby/)
  end

  def rrequire(project, feature, background, loadPathLevel=0)

    encoding = "UTF-8"

    lplevel = @context.loadPathLevel
    @context.loadPathLevel = loadPathLevel
    if lplevel > 2 && background == false
      return @placeholders << [project, feature]
    end

    return LoadResult.alreadyLoaded() if project.loaded?(feature)

    if PROJMAN && PROJMAN.roptions && PROJMAN.roptions.project_path
      project_matches = Dir.glob(Pathname.new(PROJMAN.roptions.project_path).join("**/#{feature}*"))
      if project_matches
        project_matches.each do |p|
          return rload(project, p, "UTF-8", false)
        end
      end
    end

    stubs = stub_matches(project, feature)
    stubs.each do |stub|
      return rload(project, Pathname.new(stub), encoding, false)
    end

    lpmatches = load_path_matches(project, feature)
    lpmatches.each do |lp|
      return rload(project, lp, encoding, false)
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
  end

  def load_builtin(project)
    builtin = builtin_path(project)
    rload(project, builtin, "UTF-8", false)
    project.stubs.each do |p|
      rload(project, Pathname.new(p), "UTF-8", false) unless p.match(/builtin/)
    end
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
    prepare(@project)
    if code_str.empty?
      code = Rsense::Server::Code.new(Pathname.new(file).read)
    else
      code = Rsense::Server::Code.new(code_str)
    end

    begin
      source = code.inject_inference_marker(location)
      @ast = @parser.parse_string(source, file.to_s)
      @project.graph.load(@ast)
      # result = Java::org.cx4a.rsense::CodeCompletionResult.new
      # result.setAST(@ast)
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
    @native_attr_method.graph = @graph
    @graph.addSpecialMethod(Rsense::Server::Command::TYPE_INFERENCE_METHOD_NAME, @type_inference_method)
    @graph.addSpecialMethod("require", @require_method)
    @graph.addSpecialMethod("require_next", @require_next_method)
    @graph.addSpecialMethod("require_relative", @require_relative_method)
    @graph.addSpecialMethod("native_accessor", @native_attr_method)
    @graph.addSpecialMethod("alias_native", @alias_native_method)
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

  def set_features_loaded(deps)
    deps.each do |d|
      @project.loaded << d.name
    end
  end

  def prepare_project()
    if @options.name
      name = @options.name
    else
      name = "(sandbox)"
    end
    file = @options.project_path
    @project = Rsense::Server::Project.new(name, file)
    prepare(project)
    set_features_loaded(@project.dependencies)
    codes = Rsense::Server::Command::Preload.dependency_code(@project.dependencies)
    codes.each_with_index do |c, i|
      load_gem(@project, c, i)
    end
  end

end
