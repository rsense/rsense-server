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

  def visitLocalVarNode(node)
    holder = self.runtime.getContext().getCurrentScope().getValue(node.getName())
    if node.name.match(/block/)
      binding.pry
    end

    if holder
      holder.getVertex()
    else
      Java::org.cx4a.rsense.typing.vertex::Vertex::EMPTY
    end
  end
end
