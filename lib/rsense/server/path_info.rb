require "filetree"

require_relative './version'

module Rsense
  module Server
    module PathInfo

      RSENSE_SERVER_HOME = FileTree.new(File.dirname(__FILE__)).expand_path.ancestors[2]

      def self.bin_path
        RSENSE_SERVER_HOME.join("bin/_rsense.rb")
      end

    end
  end
end
