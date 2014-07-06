java_import Java::org.cx4a.rsense.typing.vertex::MultipleAsgnVertex

module Rsense
  module Server
    module Command

    end
  end
end

class Rsense::Server::Command::RuntimeHelper < Java::org.cx4a.rsense.typing.runtime::RuntimeHelper

  def self.getNamespace(graph, node)
    if node.class.to_s.match(/Colon2ConstNode/)
      left = graph.createVertex((node).getLeftNode())
      object = left.singleType()
      if object && object.java_object.java_kind_of?(Java::org.cx4a.rsense.ruby::RubyModule)
        return object
      else
        return nil
      end
    else
      super
    end
  end

  def self.get_namespace(graph, node)
    self.getNamespace(graph, node)
  end
end
