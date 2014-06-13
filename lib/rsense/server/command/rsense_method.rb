require "jruby-parser"

module Rsense
  module Server
    module Command
      class RsenseMethod < Java::org.cx4a.rsense.typing.runtime::DefaultMethod
        attr_accessor :cbase, :name, :body_node, :args_node, :visibility, :location, :node, :parent

        def initialize(cbase, name, bodyNode, argsNode, visibility, location)
          super(cbase, name, bodyNode, argsNode, visibility, location)
        end

        def self.make_method(cbase, name, visibility, parent)
          node = self.make_node(name, parent)
          loc = Java::org.cx4a.rsense.util::SourceLocation.of(node)
          [cbase, name, node.body_node, node.args_node, visibility, loc]
        end

        def self.make_node(name, parent)
          self.generate_node(name, parent)
        end

        def self.generate_method_body(name)
          %Q{
              def #{name}(*args)
                if block_given?
                  yield args
                else
                  args
                end
              end
            }
        end

        def self.generate_node(name, parent)
          code = self.generate_method_body(name)
          root = JRubyParser.parse(code)
          node = root.find_node(:defn)
          self.insert_into_parent(node, parent)
        end

        def self.insert_into_parent(node, parent)
          parent = parent
          parent.insert_node(node)
          inserted_node = parent.find_all.select {|n| n == node}.first
          if inserted_node
            inserted_node
          else
            node
          end
        end

      end
    end
  end
end
