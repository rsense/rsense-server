require "pathname"
require "bundler"

module Rsense
  module Server
    module LoadPath

      Dependency = Struct.new(:name, :full_name, :path)

      module_function
      def paths
        fetch.map { |p| p unless p.to_s =~ /^file:/ }
      end

      def fetch
        $LOAD_PATH
      end

      def dependencies(project)
        @deps = []
        @gemfile = find_gemfile(project)
        if @gemfile
          start_dir = Dir.pwd
          Dir.chdir(@gemfile.dirname)
          lockfile = Bundler::LockfileParser.new(Bundler.read_file(@gemfile))
          @deps = gem_info(lockfile)
          Dir.chdir(start_dir)
        end
        @deps
      end

      def gem_info(lfile)
        lfile.specs.map do |s|
          generate_struct(s.name, s.version)
        end
      end

      def generate_struct(name, version)
        paths = check_version(find_paths(name), version)
        Dependency.new(name, "#{name}-#{version.to_s}", paths)
      end

      def check_version(gem_paths, version)
        gem_paths.select do |p|
          p.to_s =~ /#{version}/
        end
      end

      def find_paths(name)
        paths = Gem.find_files(name)
        return paths unless paths.empty? && name.length > 1
        find_paths(name.chop)
      end

      def find_gemfile(project, level=0)
        level = level + 1
        pth = Pathname.new(project).expand_path
        lockfile = pth.join("Gemfile.lock")
        if lockfile.exist?
          return lockfile
        else
          unless level > 6
            lockfile = find_gemfile(pth.parent, level)
          end
        end
      end

    end
  end
end
