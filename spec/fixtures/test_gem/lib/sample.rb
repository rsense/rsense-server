require "sample/version"

class Sample
  attr_accessor :simple

  def initialize
    @simple = "simple"
  end

  def another
    "another"
  end
end

sample = Sample.new
sample
