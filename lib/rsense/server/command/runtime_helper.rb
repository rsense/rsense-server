java_import Java::org.cx4a.rsense.typing.vertex::MultipleAsgnVertex

module Rsense
  module Server
    module Command

    end
  end
end

class Java::org.cx4a.rsense.typing.runtime::RuntimeHelper

  def multipleAssign(graph, node, src)
    unless src
      src = graph.createVertex(node.getValue())
    end

    vertex = MultipleAsgnVertex.new(node, src)
    graph.addEdgeAndPropagate(src, vertex)
    src
  end

end
