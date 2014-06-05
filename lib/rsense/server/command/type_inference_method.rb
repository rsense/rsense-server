module Rsense
  module Server
    module Command

    end
  end
end

class Rsense::Server::Command::TypeInferenceMethod < Java::org.cx4a.rsense.typing.runtime::SpecialMethod
  attr_accessor :context

  def initialize
    super
  end

  def call(runtime, receivers, args, blcck, result)
    receivers.each do |receiver|
      @context.typeSet.add(receiver)
    end
    result.setResultTypeSet(receivers)
    result.setNeverCallAgain(true)
  end

end
