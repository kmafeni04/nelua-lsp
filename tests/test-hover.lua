local lester = require("libs.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect
local hover = require("methods.hover")

local pos_to_line_char = require("utils.pos_to_line_char")
local analyze_ast = require("utils.analyze_ast")

describe("Hover tests", function()
  it("Variable", function()
    local current_file_path = "/home/user/Desktop/test.nelua"
    local current_file_content = "local x = 1"
    local ast = analyze_ast(current_file_content, current_file_path)
    assert(ast)
    local line, char = pos_to_line_char(7, current_file_content)
    local request_params = {
      position = {
        line = line,
        character = char,
      },
    }
    local result = hover(request_params, current_file_content, current_file_path, ast)
    local expected_result = "x\n```nelua\nType: int64\n```"
    expect.truthy(result == expected_result)
  end)
  it("Documentation", function()
    local current_file_path = "/home/user/Desktop/test.nelua"
    local current_file_content = "-- test doc\nlocal x = 1"
    local ast = analyze_ast(current_file_content, current_file_path)
    assert(ast)
    local line, char = pos_to_line_char(19, current_file_content)
    local request_params = {
      position = {
        line = line,
        character = char,
      },
    }
    local result = hover(request_params, current_file_content, current_file_path, ast)
    local expected_result = "x\n```nelua\nType: int64\n```\n\n`---`\n\ntest doc\n"
    expect.truthy(result == expected_result)
  end)
end)

lester.report()
lester.exit()
