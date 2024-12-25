-- TODO: For unused variables, rework how they are identified as the same name and
-- type in two seperate functions will be treated as used if one of them is used
local sstream = require("nelua.utils.sstream")

local analyze_ast = require("utils.analyze_ast")
local logger = require("utils.logger")
local server = require("utils.server")
local pos_to_line_and_char = require("utils.pos_to_line_char")

---@enum Severity
local Severity = {
  Error = 1,
  Warning = 2,
  Information = 3,
  Hint = 4,
}

---@param node table
---@param foundnodes table
---@param mark table
local function traverse_nodes_and_mark(node, foundnodes, mark)
  if type(node) ~= "table" then
    return nil, "Node passed to find_nodes_by_pos was not a table"
  end

  if node._astnode then
    foundnodes[#foundnodes + 1] = node
    if node.attr and node.attr.name and node.pos and (node.attr.used or node.is_Id) then
      mark[node.attr.name .. "//" .. tostring(node.attr.type)] = true
    elseif node.attr.global then
      mark[node.attr.name .. "//" .. tostring(node.attr.type)] = true
    elseif (node.is_DotIndex or node.is_ColonIndex) and node[2].attr.global then
      mark[node.attr.name .. "//" .. tostring(node.attr.type)] = true
    elseif node.is_Return then
      for _, child in ipairs(node) do
        if type(child) == "table" and child.is_Id and child.attr.type and child.attr.type.is_type then
          for _, _node in pairs(foundnodes) do
            if
              (_node.is_DotIndex or _node.is_ColonIndex) and tostring(child.attr.type) == tostring(_node[2].attr.type)
            then
              mark[_node.attr.name .. "//" .. tostring(_node.attr.type)] = true
            end
          end
        end
      end
    end
  end
  for i = 1, node.nargs or #node do
    traverse_nodes_and_mark(node[i], foundnodes, mark)
  end
  return foundnodes, nil
end

---@param analysis string
---@param analysis_match string
---@param severity integer
---@param current_file_path string
---@return Diagnsotic
local function create_diagnostic_fields(analysis, analysis_match, severity, current_file_path)
  ---@class Diagnsotic
  ---@field severity integer
  ---@field uri string
  ---@field line integer
  ---@field s_char integer
  ---@field e_char integer
  ---@field msg string
  local diagnostic = {}

  for line in analysis:gmatch("([^\r\n]+)") do
    local diag_path, diag_line, diag_s_char, diag_msg = line:match(analysis_match)
    if diag_path then
      local analysis_search_reg = diag_msg:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
      local analysis_search_start = analysis:find(analysis_search_reg)
      local error_len_str = analysis:match("%^~+[^\r\n]", analysis_search_start)
      local error_len = 1
      if error_len_str then
        error_len = #error_len_str
      end
      local diag_uri = "file://" .. current_file_path:match("(.+/).*%.nelua") .. diag_path

      diagnostic.severity = severity
      diagnostic.uri = diag_uri
      diagnostic.line = tonumber(diag_line) - 1
      diagnostic.s_char = tonumber(diag_s_char) - 1
      diagnostic.e_char = diagnostic.s_char + error_len
      diagnostic.msg = diag_msg

      if diagnostic.s_char < 0 then
        diagnostic.line = diagnostic.line - 1
        diagnostic.s_char = 0
        diagnostic.e_char = 1
      end

      break
    end

    local extern_path, extern_line, extern_msg = line:match("(.-):(%d+):%s+error:%s+([^\r\n]+)")
    if extern_path then
      for l in analysis:gmatch("[^\r\n]+") do
        local extern_analysis_match = "(.-):(%d+):(%d+):%s*from:"
        diag_path, diag_line, diag_s_char = l:match(extern_analysis_match)
        if diag_path then
          local analysis_search_start = analysis:find(extern_analysis_match)
          local error_len_str = analysis:match("%^~+[^\r\n]", analysis_search_start)
          local error_len = 1
          if error_len_str then
            error_len = #error_len_str
          end

          local diag_uri = "file://" .. current_file_path:match("(.+/).*%.nelua") .. diag_path
          diagnostic.severity = severity
          diagnostic.uri = diag_uri
          diagnostic.line = tonumber(diag_line) - 1
          diagnostic.s_char = tonumber(diag_s_char) - 1
          diagnostic.e_char = diagnostic.s_char + error_len
          diagnostic.msg = extern_path .. ":" .. extern_line .. ": " .. extern_msg
          break
        end
      end
      break
    end
  end

  return diagnostic
end

---@param current_file_content string
---@param current_file_path string
---@param current_uri string
---@return table? ast
return function(current_file_content, current_file_path, current_uri)
  current_file_content = current_file_content
  local diagnostics = {}
  local ast, err = analyze_ast(current_file_content, current_file_path)
  if err then
    if err.message:match(":%s*error:") then
      local diag = create_diagnostic_fields(
        err.message,
        "(.-):(%d+):(%d+):%s+error:%s+([^\r\n]+)",
        Severity.Error,
        current_file_path
      )
      local diagnostic = {
        range = {
          start = { line = diag.line, character = diag.s_char },
          ["end"] = { line = diag.line, character = diag.e_char },
        },
        message = diag.msg,
        severity = diag.severity,
      }
      table.insert(diagnostics, diagnostic)
      server.send_notification("textDocument/publishDiagnostics", {
        uri = current_uri,
        diagnostics = diagnostics,
      })
      return nil
    elseif err.message:match(":%s*syntax error:") then
      local diag = create_diagnostic_fields(
        err.message,
        "(.-):(%d+):(%d+):%s+syntax error:%s+([^\r\n]+)",
        Severity.Error,
        current_file_path
      )
      local diagnostic = {
        range = {
          start = { line = diag.line, character = diag.s_char },
          ["end"] = { line = diag.line, character = diag.e_char },
        },
        message = diag.msg,
        severity = diag.severity,
      }
      table.insert(diagnostics, diagnostic)
      server.send_notification("textDocument/publishDiagnostics", {
        uri = current_uri,
        diagnostics = diagnostics,
      })
      return nil
    else
      local diagnostic = {
        range = {
          start = { line = 0, character = 0 },
          ["end"] = { line = 0, character = 1 },
        },
        message = "There is an unknown error",
        severity = Severity.Error,
      }
      table.insert(diagnostics, diagnostic)
      server.send_notification("textDocument/publishDiagnostics", {
        uri = current_uri,
        diagnostics = diagnostics,
      })
      return nil
    end
  else
    local nodes = {}
    local mark = {}
    for _, node in
      pairs(ast --[[@as table]])
    do
      traverse_nodes_and_mark(node, nodes, mark)
    end

    for _, node in pairs(nodes) do
      if
        node.attr
        and node.attr.name
        and node.pos
        and not mark[node.attr.name .. "//" .. tostring(node.attr.type)]
        and not node.is_FuncDef
      then
        local pos = node.pos
        local s_line, s_char = pos_to_line_and_char(pos, current_file_content)
        local ss = sstream()
        local msg = ""
        ss:add("Unused")
        if node.is_IdDecl then
          ss:addmany(" Variable `", node.attr.name, "`")
        elseif node.is_Label then
          ss:addmany(" Label `", node.attr.name, "`")
          node.attr.name = "::" .. node.attr.name .. "::"
        elseif (node.is_DotIndex and node.attr.ftype) or node.is_ColonIndex then
          s_char = s_char + 1
          ss:addmany(" Function `", node.attr.name, "`")
          node.attr.name = node[1]
        else
          ss:addmany(" `", node.attr.name, "`")
        end
        msg = ss:tostring()
        local diagnostic = {
          range = {
            start = { line = s_line, character = s_char },
            ["end"] = { line = s_line, character = s_char + #node.attr.name },
          },
          message = msg,
          severity = Severity.Hint,
        }
        table.insert(diagnostics, diagnostic)
      end
    end
    server.send_notification("textDocument/publishDiagnostics", {
      uri = current_uri,
      diagnostics = diagnostics,
    })
    return ast
  end
end
