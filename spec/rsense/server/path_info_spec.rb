require_relative "../../spec_helper.rb"

describe Rsense::Server::PathInfo do
  it "knows where its home is" do
    Rsense::Server::PathInfo::RSENSE_SERVER_HOME.to_s.must_match(/rsense-server$/)
  end

  it "knows where to find the bin file" do
    Rsense::Server::PathInfo.bin_path.to_s.must_match(/rsense-server\/bin\/_rsense.rb$/)
  end
end
