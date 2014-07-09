module Rsense
  module Server
    module Command
      class Preload
        SourceCode = Struct.new(:name, :full_name, :path,  :files, :source)

        def self.stub_data(path)
          { "project" => path.to_s }
        end

        def self.load(project_manager, path)
          PROJMAN.roptions = Rsense::Server::Options.new(stub_data(path))
          PROJMAN.rcommand = Rsense::Server::Command::Command.new(PROJMAN.roptions)
        end

        def self.dependency_code(dependencies)
          paths = dependencies.map { |d| gen_source(d) }.compact!
          return [] unless paths
          lib_dirs(paths)
          code(paths)
          paths.each { |l| concat_files(l) }
        end

        def self.gen_source(d)
          SourceCode.new(d.name, d.full_name, d.path.first) if d.path.first
        end

        def self.code(libs)
          libs.each do |l|
            l.files = Dir.glob(Pathname.new(l.path).join("**/*.rb"))
          end
        end

        def self.concat_files(paths)
          code = paths.files.map { |f| Pathname.new(f).read }
          paths.source = code.join("\n")
        end

        def self.lib_dirs(paths)
          paths.each { |p|
            p.path = find_lib(p)
          }
        end

        def self.find_lib(path)
          p = Pathname.new(path.path).expand_path
          return p.dirname if p.file?
          return p
        end

      end
    end
  end
end
