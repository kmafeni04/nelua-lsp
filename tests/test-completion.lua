local pos_to_line_char = require("utils.pos_to_line_char")
local lester = require("libs.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect
local completion = require("methods").completion

describe("Completion tests", function()
  it("Return Prefixed Items", function()
    local current_file_path = "/home/user/Desktop/test.nelua"
    local current_uri = "file://" .. current_file_path
    local current_file_content = "local x = 1 loc"
    local documents = {
      [current_uri] = current_file_content,
    }
    local line, char = pos_to_line_char(#current_file_content, current_file_content)
    local request_id = 1
    local request_params = {
      position = {
        line = line,
        character = char,
      },
    }
    local ast_cache = {}
    ---@type table?, CompItem[]
    local _, items =
      completion(request_id, request_params, documents, current_uri, current_file_path, current_file_content, ast_cache)
    --[[ 
        local comp_item = {
          label = label,
          kind = kind,
          documentation = doc,
          insertText = inser_text,
          insertTextFormat = fmt,
        }
      ]]
    local expected_items = {
      { label = "local" },
      { label = "local function" },
    }
    expect.falsy(#items > #expected_items)
    local equal = true
    for i = 1, #expected_items do
      if items[i].label ~= expected_items[i].label then
        equal = false
      end
    end
    expect.truthy(equal)
  end)
end)

lester.report()
lester.exit()
