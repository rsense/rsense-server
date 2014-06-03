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

  attr_accessor :context, :options, :parser, :projects, :sandbox, :definitionFinder, :whereListener, :type_inference_method, :require_method, :require_next_method, :result

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

  def open_project(project)
    @projects[project.name] = project
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
