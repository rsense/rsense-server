module Rsense
  module Server
    module Command
      module Preload

        def stub_data(path)
          { "project" => path.to_s }
        end
        module_function :stub_data

        def load(project_manager, path)
          PROJMAN.roptions = Rsense::Server::Options.new(stub_data(path))
          PROJMAN.rcommand = Rsense::Server::Command::Command.new(PROJMAN.roptions)
        end

        module_function :load

      end
    end
  end
end
