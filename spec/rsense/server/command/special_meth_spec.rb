require_relative "../../../spec_helper"

describe Rsense::Server::Command::SpecialMeth do
  before do
    @spec_meth = Rsense::Server::Command::SpecialMeth.new() do |runtime, receivers, args, blcck, result|
      { runtime: runtime,
        receivers: receivers,
        args: args,
        blcck: blcck,
        result: result
      }
    end
  end

  it "calls block with args" do
    meth_hash = @spec_meth.call("run", "rec", "args", "blcck", "result")
    meth_hash[:runtime].must_match(/run/)
    meth_hash[:receivers].must_match(/rec/)
    meth_hash[:args].must_match(/args/)
    meth_hash[:blcck].must_match(/blcck/)
    meth_hash[:result].must_match(/result/)
  end
end
