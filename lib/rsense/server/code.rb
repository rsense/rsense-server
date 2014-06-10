module Rsense
  module Server
    class Code
      attr_accessor :lines
      TYPE_INFERENCE_METHOD_NAME = Rsense::Server::Command::TYPE_INFERENCE_METHOD_NAME
      FIND_DEFINITION_METHOD_NAME_PREFIX = Rsense::Server::Command::FIND_DEFINITION_METHOD_NAME_PREFIX

      def initialize(code_str)
        @lines = code_str.split("\n")
      end

      def inject_inference_marker(location)
        row = location["row"] - 1
        column = location["column"] - 1
        lines = @lines.clone
        line = lines[row]
        return lines.join("\n") unless line && line.length >= column - 1 && column > 1
        if line.slice(column - 1).end_with?(".")
          line.insert(column, TYPE_INFERENCE_METHOD_NAME)
        elsif line.slice(column - 2..column - 1).end_with?("::")
          line.insert(column, TYPE_INFERENCE_METHOD_NAME)
        else
          line.insert(column, ".#{TYPE_INFERENCE_METHOD_NAME}")
        end
        lines.join("\n")
      end

      def inject_definition_marker(injection, location)
        row = location["row"] - 1
        column = location["column"] - 1
        lines = @lines.clone
        line = lines[row]
        match = line.slice(0, column).match(/.*(?:\.|::|\s)(\w+?[!?]?)/)
        start = match.end(0)
        line.insert(start - 1, injection)
        lines.join("\n")
      end

    end
  end
end
