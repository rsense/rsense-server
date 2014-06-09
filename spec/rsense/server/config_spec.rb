require "filetree"
require_relative "../../spec_helper"

describe Rsense::Server::Config do
  before do
    @path = "spec/fixtures/config_fixture"
    @conf_path = FileTree.new("spec/fixtures/config_fixture/.rsense").expand_path
    @config = Rsense::Server::Config.new
  end

  it "searches for a config file" do
    search = @config.search(@path)
    search.to_s.must_match(/spec\/fixtures\/config_fixture\/\.rsense/)
    @config.searched.size.must_equal(1)
  end

  it "sets the port" do
    options = @config.options(@conf_path)
    @config.port.must_equal(123456)
  end

  it "sets ignores" do
    options = @config.options(@conf_path)
    @config.ignores.must_include(".foo")
    @config.ignores.must_include(".bar")
  end
end
