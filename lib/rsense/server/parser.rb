require "jruby-parser"

module Rsense
  module Server
    class Parser
      include JRubyParser
      PCONFIG = org.jrubyparser.parser.ParserConfiguration

      def parse_string(source_string, filename='')
        filename = filename || '(string)'
        version = org.jrubyparser.CompatVersion::RUBY2_0
        config = PCONFIG.new(0, version)
        config.setSyntax(PCONFIG::SyntaxGathering::COMMENTS);
        reader = java.io.StringReader.new(source_string)
        org.jrubyparser.Parser.new.parse(filename, reader, config)
      end

    end
  end
end
