require_relative "./runtime_helper"

module Rsense
  module Server
    module Command

    end
  end
end

class Rsense::Server::Command::Vertex < Java::org.cx4a.rsense.typing.vertex::Vertex

  def addType(type)
    unless type
      return false
    end
    super
  end
end

class Rsense::Server::Command::Graph < Java::org.cx4a.rsense.typing::Graph
  RuntimeHelper = Rsense::Server::Command::RuntimeHelper
  attr_accessor :context

  def initialize
    super
    @context = self.runtime.getContext
  end

  def visitDefnNode(node)
    name = node.getName()
    if name.match(/new/)
      return Java::org.cx4a.rsense.typing.vertex::Vertex::EMPTY
    end
    super
  end

  def visitDefsNode(node)
    name = node.getName()
    if name.match(/new/)
      return Java::org.cx4a.rsense.typing.vertex::Vertex::EMPTY
    end
    super
  end

  def visitColon2Node(node)
    target = RuntimeHelper.getNamespace(self, node)
    super
  end

  def visitClassNode(node)
    cpath = node.getCPath()
    name = cpath.getName()
    RuntimeHelper.getNamespace(self, cpath)
    super
  end

  def visitFCallNode(node)
    if node.name.match(/filter!/)
      if node.getArgs && node.getArgs.getNodeType == Java::org.jrubyparser.ast::NodeType::BLOCKPASSNODE
        block_pass = node.getArgs()
        argVertices = RuntimeHelper.setupCallArgs(self, block_pass.getArgs())
        block = RuntimeHelper.setupCallBlock(self, block_pass)
      else
        argVertices = RuntimeHelper.setupCallArgs(self, node.getArgs())
        block = RuntimeHelper.setupCallBlock(self, node.getIter())
      end
      vertex = Java::org.cx4a.rsense.typing.vertex::CallVertex.new(node, createFreeSingleTypeVertex(context.getFrameSelf()), argVertices, block)
      vertex.setPrivateVisibility(true)
      return RuntimeHelper.call(self, vertex)
    end
    super
  end

  def createFreeSingleTypeVertex(type)
    vertex = createFreeVertex()
    vertex.addType(type)
    return vertex
  end

  def createFreeVertex(typeSet=nil)
    if typeSet
      return Rsense::Server::Command::Vertex.new(nil, typeSet)
    else
      return Rsense::Server::Command::Vertex.new
    end
  end
end
