require "sample/version"

module Sample
  class Sample
    attr_accessor :simple

    def initialize
      @simple = "simple"
    end

    def another
      "another"
    end
  end
end

sample = Sample::Sample.new
sample
