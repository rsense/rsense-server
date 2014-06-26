module Rsense
  module Server
    module Command
      module Preload

        def stub_data(path)
          filepath = path.join("/lib/code.rb")
          {
            "command"=>"code_completion",
            "project" => path.to_s,
            "file" =>  filepath.to_s,
            "code" => "def check(testarg)\n  testarg\nend\ncheck('hello')",
            "location" => { "row" => 2, "column" => 10 }
          }
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
