module Rsense
  module Server
    module Command

    end
  end
end

class Rsense::Server::Command::AliasNativeMethod < Java::org.cx4a.rsense.typing.runtime::SpecialMethod
  attr_accessor :context

  def initialize
    super
  end

  def call(runtime, receivers, args, blcck, result)
    callNextMethod = true
    if args
      receivers.each do |receiver|
        callNextMethod = false
        new_name = Java::org.cx4a.rsense.typing.vertex::Vertex.getStringOrSymbol(args[0])
        if args.size > 1
          old_name = Java::org.cx4a.rsense.typing.vertex::Vertex.getStringOrSymbol(args[1])
        end
        rsense_module = receiver
        visibility = Java::org.cx4a.rsense.ruby::Visibility::PUBLIC
        if old_name && new_name
          rcbase, rname, rbodyNode, rargsNode, rvisibility, rlocation = Rsense::Server::Command::RsenseMethod.make_method(rsense_module, old_name, visibility, args.first.node.parent)
          rsense_method = Rsense::Server::Command::RsenseMethod.new(rcbase, rname, rbodyNode, rargsNode, rvisibility, rlocation)
          rsense_module.addMethod(old_name, rsense_method)
          rsense_module.addMethod(new_name, Java::org.cx4a.rsense.typing.runtime::AliasMethod.new(new_name, rsense_method))
        else
          rcbase, rname, rbodyNode, rargsNode, rvisibility, rlocation = Rsense::Server::Command::RsenseMethod.make_method(rsense_module, new_name, visibility, args.first.node.closest_module)
          rsense_method = Rsense::Server::Command::RsenseMethod.new(rcbase, rname, rbodyNode, rargsNode, rvisibility, rlocation)
          rsense_module.addMethod(new_name, rsense_method)
        end
      end
    end
    result.setCallNextMethod(callNextMethod)
  end

end
