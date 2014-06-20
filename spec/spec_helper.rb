require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!

require "rsense-core"

require_relative "../lib/rsense/server/command.rb"
require_relative "../lib/rsense/server/gem_path.rb"
require_relative "../lib/rsense/server/load_path.rb"
require_relative "../lib/rsense/server/options.rb"
require_relative "../lib/rsense/server/code.rb"
require_relative "../lib/rsense/server.rb"
require_relative "../lib/rsense/server/path_info.rb"
require_relative "../lib/rsense/server/command/special_meth.rb"
require_relative "../lib/rsense/server/project.rb"
require_relative "../lib/rsense/server/config.rb"

class ProjectManager
  attr_accessor :roptions, :rcommand, :rproject
end

PROJMAN = ProjectManager.new
