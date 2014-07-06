require_relative "./spec_helper"
require "pathname"
require "json"

describe "completions" do

    class TestMockscript
      attr_accessor :json_path, :json, :options, :command, :name, :file, :project

      def initialize
        @json_path = Pathname.new("spec/fixtures/test_gem/test.json").expand_path
        @json = JSON.parse(@json_path.read)
        @options = Rsense::Server::Options.new(@json)
        @command = Rsense::Server::Command::Command.new(@options)
      end

      def code_complete
        @command.code_completion(@options.file, @options.location)
      end
    end

    it "returns completions" do
      @script = TestMockscript.new
      compls = @script.code_complete
      compls.size.must_equal(66)
    end

end
