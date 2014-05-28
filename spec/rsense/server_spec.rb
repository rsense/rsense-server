require_relative "../spec_helper"

describe Rsense::Server do
  it "loads" do
    Rsense::Server.class.must_equal Module
  end
end
