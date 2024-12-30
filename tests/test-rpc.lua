local lester = require("libs.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect
local rpc = require("utils.rpc")

describe("RPC tests", function()
  it("Encode", function()
    local tbl = {
      name = "james",
      age = "20",
    }
    local result = rpc.encode(tbl)
    local expected_len = #"Content-Length: 27\r\n\r\n" + 27
    expect.truthy(type(result) == "string")
    expect.truthy(#result == expected_len)
  end)
  it("Decode", function()
    local to_decode = '{"age":"20","name":"james"}'
    local result = rpc.decode(to_decode)
    expect.truthy(result)
    expect.truthy(result.name and result.age)
  end)
end)
lester.report()
lester.exit()
