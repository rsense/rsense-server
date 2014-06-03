require "pathname"

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
        @gemfile = find_gemfile(project)
        if @gemfile
          lockfile = Bundler::LockfileParser.new(Bundler.read_file(@gemfile))
          gem_info(lockfile)
        end
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

      def find_gemfile(project)
        pth = Pathname.new(project).expand_path
        lockfile = Dir.glob(pth.join("**/Gemfile.lock")).first
        unless lockfile
          unless pth.parent == pth
            lockfile = find_gemfile(pth.parent)
          end
        end
        lockfile
      end

    end
  end
end
