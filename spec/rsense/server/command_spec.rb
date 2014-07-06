require "pathname"
require "json"
require_relative "../../spec_helper.rb"

describe Rsense::Server::Command::Command do
  json_path = Pathname.new("spec/fixtures/sample.json")
  json = JSON.parse(json_path.read)
  OPTIONS = Rsense::Server::Options.new(json)
  COMMAND = Rsense::Server::Command::Command.new(OPTIONS)

  it "can be initialized" do
    Rsense::Server::Command::Command.new(OPTIONS)
  end

  describe "finding dependencies" do
    Dependency = Struct.new(:name, :full_name, :path)
    Project = Struct.new(:load_path, :gem_path, :stubs)

    before do
      @dependencies = [
        Dependency.new("foo", "foo.1.2", ["/foo/bar/baz"]),
        Dependency.new("scooby", "scooby.1.2", ["/scooby/dooby/doo"])
      ]
      @loadpath = [
        "spec/fixtures",
        "/bada/bing/bang/boom"
      ]
      @gempath = [
        "/fee/fi/fo/fum",
        "/i/smell/the/blood/of/an/englishman"
      ]
      @stubs = Dir.glob(Rsense::BUILTIN.join("**/*.rb"))
      @project = Project.new("(test-sandbox)", "spec/fixtures/test_gem/", @stubs)
    end

    it "finds the dependency" do
      matches = COMMAND.dependency_matches(@dependencies, "foo")
      matches.first.to_s.must_match(/baz/)
    end

    it "does not find a dependency which is not there" do
      COMMAND.dependency_matches(@dependencies, "scoby").must_be_empty
    end

    it "finds the path in the load_path" do
      @project.load_path = @loadpath
      COMMAND.load_path_matches(@project, "def_sample").size.must_equal(1)
    end

    it "gathers the lib directory paths from the dependencies" do
      deps = [
        Dependency.new("foo", "foo.1.2", ["/foo/lib/foo.rb"]),
      ]
      paths = COMMAND.dependency_paths(deps)

      paths.to_s.must_match(/\/foo\/lib/)
    end

    it "finds a deeply nested path" do
      dep_paths = [Pathname.new("spec/fixtures/deeply"), Pathname.new("foo/bar/baz")]
      matches = COMMAND.deep_check(@gempath, dep_paths, "thing")
      matches.first.must_match(/nested/)
      matches.size.must_equal(1)
    end

    it "finds the stubs" do
      matches = COMMAND.stub_matches(@project, "_builtin")
      matches.size.must_equal(1)
    end

    it "finds the _builtin" do
      COMMAND.builtin_path(@project).to_s.must_match(/_builtin/)
    end
  end

end
