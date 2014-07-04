require "pry"

module Rsense
  module Server
    module Command

    end
  end
end

class Rsense::Server::Command::Graph < Java::org.cx4a.rsense.typing::Graph

  def initialize
    super
  end

  def visitMultipleAsgnNode(node)
    Java::org.cx4a.rsense.typing.runtime::RuntimeHelper.multipleAssign(self, node)
  end

  def addEdgeAndPropagate(src, dest)
    src.addEdge(dest)
    propagate(src, dest)
  end
end
