module Rsense
  module Server
    module Command

    end
  end
end

class Rsense::Server::Command::NativeAttrMethod < Java::org.cx4a.rsense.typing.runtime::SpecialMethod
  attr_accessor :context, :graph

  def initialize
    super
  end

  def call(runtime, receivers, args, blcck, result)
    Java::org.cx4a.rsense.typing.runtime::RuntimeHelper.defineAttrs(@graph, receivers, args, true, true)
  end

end
