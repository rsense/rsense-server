module Rsense
  module Server
    module Command
      class SpecialMeth < Java::org.cx4a.rsense.typing.runtime::SpecialMethod
        attr_accessor :call_block

        def initialize(&code)
          @call_block = code
        end

        def call(*args)
          @call_block.call(*args)
        end

      end
    end
  end
end
