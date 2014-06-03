require "pathname"
require "json"
require_relative "../../spec_helper.rb"

describe Rsense::Server::Command::Command do
  before do
    @json_path = Pathname.new("spec/fixtures/sample.json")
    @json = JSON.parse(@json_path.read)
    @options = Rsense::Server::Options.new(@json)
  end

  it "can be initialized" do
    Rsense::Server::Command::Command.new(@options)
  end
end
