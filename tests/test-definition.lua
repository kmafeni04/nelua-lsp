local lester = require("libs.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect
local definition = require("methods.definition")

local pos_to_line_char = require("utils.pos_to_line_char")
local analyze_ast = require("utils.analyze_ast")
local equals = require("utils.equals")

describe("Definition tests", function()
  it("Go to variable", function()
    local root_path = "/home/user/Desktop/test"
    local current_file_path = "/home/user/Desktop/test/variable.nelua"
    local current_uri = "file://" .. current_file_path
    local current_file_content = "local x = 1\nprint(x)"
    local documents = {
      [current_uri] = current_file_content,
    }
    local current_line, current_char = pos_to_line_char(#current_file_content - 1, current_file_content)
    local ast = analyze_ast(current_file_content, current_file_path)
    assert(ast, "Ast should not be nil")
    local locs =
      definition(root_path, documents, current_file_content, current_file_path, current_line, current_char, ast)
    expect.truthy(next(locs))
    local expected_result = {
      uri = current_uri,
      range = {
        start = {
          line = 0,
          character = 6,
        },
        ["end"] = {
          line = 0,
          character = 7,
        },
      },
    }
    expect.truthy(equals(expected_result, locs[1]))
  end)
end)

lester.report()
lester.exit()
