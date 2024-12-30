local lester = require("libs.lester")
local describe, it, expect = lester.describe, lester.it, lester.expect
local completion = require("methods").completion

local pos_to_line_char = require("utils.pos_to_line_char")
local analyze_ast = require("utils.analyze_ast")

describe("Completion tests", function()
  it("Prefixed Items", function()
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
    expect.truthy(#items == #expected_items)

    local not_checked = #items
    for i = 1, #items do
      for j = 1, #expected_items do
        if items[i].label == expected_items[j].label then
          not_checked = not_checked - 1
        end
      end
    end
    expect.truthy(not_checked == 0)
  end)
  it("Colon Items", function()
    local current_file_path = "/home/user/Desktop/test.nelua"
    local current_uri = "file://" .. current_file_path
    local current_file_content = [[
      local X = @record{}
      function X:test() end
      function X:test2() end
      function X:test3() end

      local x: X
      x:]]
    local documents = {
      [current_uri] = current_file_content,
    }
    local line, char = pos_to_line_char(#current_file_content, current_file_content)
    local request_id = 1
    local request_params = {
      position = {
        line = line,
        character = char + 1,
      },
      context = { triggerCharacter = ":", triggerKind = 2 },
    }
    local analyzeable_content = [[
      local X = @record{}
      function X:test() end
      function X:test2() end
      function X:test3() end

      local x: X
      ]]
    local ast = analyze_ast(analyzeable_content, current_file_path)
    local ast_cache = {
      [current_uri] = ast,
    }
    ---@type table?, CompItem[]
    local _, items =
      completion(request_id, request_params, documents, current_uri, current_file_path, current_file_content, ast_cache)
    local expected_items = {
      { label = "test" },
      { label = "test2" },
      { label = "test3" },
    }
    expect.truthy(#items == #expected_items)

    local not_checked = #items
    for i = 1, #items do
      for j = 1, #expected_items do
        if items[i].label == expected_items[j].label then
          not_checked = not_checked - 1
        end
      end
    end
    expect.truthy(not_checked == 0)
  end)
  it("Dot Items", function()
    local current_file_path = "/home/user/Desktop/test.nelua"
    local current_uri = "file://" .. current_file_path
    local current_file_content = [[
      local X = @record{}
      function X.test() end
      function X.test2() end
      function X.test3() end

      X.]]
    local documents = {
      [current_uri] = current_file_content,
    }
    local line, char = pos_to_line_char(#current_file_content, current_file_content)
    local request_id = 1
    local request_params = {
      position = {
        line = line,
        character = char + 1,
      },
      context = { triggerCharacter = ".", triggerKind = 2 },
    }
    local analyzeable_content = [[
      local X = @record{}
      function X.test() end
      function X.test2() end
      function X.test3() end
      ]]
    local ast = analyze_ast(analyzeable_content, current_file_path)
    local ast_cache = {
      [current_uri] = ast,
    }
    ---@type table?, CompItem[]
    local _, items =
      completion(request_id, request_params, documents, current_uri, current_file_path, current_file_content, ast_cache)
    local expected_items = {
      { label = "test" },
      { label = "test2" },
      { label = "test3" },
    }
    expect.truthy(#items == #expected_items)

    local not_checked = #items
    for i = 1, #items do
      for j = 1, #expected_items do
        if items[i].label == expected_items[j].label then
          not_checked = not_checked - 1
        end
      end
    end
    expect.truthy(not_checked == 0)
  end)
end)

lester.report()
lester.exit()
