require "pathname"
require "json"
require_relative "../../spec_helper"

describe Rsense::Server::Options do
  before do
    @json_path = Pathname.new("spec/fixtures/sample.json")
    @json = JSON.parse(@json_path.read)
    @options = Rsense::Server::Options.new(@json)
  end

  it "has a command" do
    @options.command.must_match(/code_completion/)
  end

  it "has a project path" do
    @options.project_path.to_s.must_match(/lib\/rsense/)
    @options.project_path.class.must_equal(Pathname)
  end

  it "has code" do
    @options.code.must_match(/def/)
  end

  it "has a location" do
    @options.location["row"].must_equal(2)
    @options.location["column"].must_equal(10)
  end

  it "has a file" do
    @options.file.to_s.must_match(/server\.rb/)
  end
end
