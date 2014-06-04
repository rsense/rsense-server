require_relative "../../spec_helper"

describe Rsense::Server::Project do
  before do
    @project = Rsense::Server::Project.new(__FILE__, File.dirname(__FILE__))
  end

  it "has stubs" do
    stubs = @project.stubs.select { |e| e.to_s =~ /_builtin/ }
    stubs.size.must_equal(1)
  end

  it "tracks loaded features" do
    @project.loaded << "feature"
    @project.loaded?("feature").must_equal(true)
    @project.loaded?("different").must_equal(false)
  end
end
