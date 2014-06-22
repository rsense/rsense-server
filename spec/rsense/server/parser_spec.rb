require_relative "../../spec_helper"

describe Rsense::Server::Parser do
  it "parses comments" do
    parser = Rsense::Server::Parser.new
    root = parser.parse_string("#a comment\n'A string'")
    root.find_node(:comment).wont_be_nil    
  end
end
