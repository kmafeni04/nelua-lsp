local logger = require("utils.logger")
local response = require("utils.response")

local did_change = require("server.did_change")
local diagnostic = require("server.diagnostic")
local completion = require("server.completion")
local hover = require("server.hover")
local definition = require("server.definition")
local rename = require("server.rename")

local server = {}

---@param request_id integer
function server.initialize(request_id)
  response.initialize(request_id)
end

---@param current_file_path string
---@return string?
-- function server.did_open(current_file_path)
--   local current_file_prog = io.open(current_file_path)
--   local current_file_path
--   if current_file_prog then
--     current_file_path = current_file_prog:read("a")
--   end
--   return current_file_path
-- end

---@param current_file_content string
---@param current_file_path string
---@param current_uri string
---@return table? ast
function server.diagnostic(current_file_content, current_file_path, current_uri)
  return diagnostic(current_file_content, current_file_path, current_uri)
end

---@param current_file_content string
---@param request_params table
---@return string
function server.did_change(current_file_content, request_params)
  return did_change(current_file_content, request_params)
end

---@param request_id integer
---@param request_params table
---@param documents table<string, string>
---@param current_file_path string
---@param current_uri string
---@param current_file_content string
---@param ast_cache table<string, table>
function server.completion(
  request_id,
  request_params,
  documents,
  current_uri,
  current_file_path,
  current_file_content,
  ast_cache
)
  return completion(
    request_id,
    request_params,
    documents,
    current_uri,
    current_file_path,
    current_file_content,
    ast_cache
  )
end

---@param request_id integer
---@param current_file_content string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
---@param ast? table
function server.hover(request_id, current_file_content, current_file_path, current_line, current_char, ast)
  hover(request_id, current_file_content, current_file_path, current_line, current_char, ast)
end

---@param request_id integer
---@param root_path string
---@param documents table<string, string>
---@param current_file_content string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
---@param ast? table
function server.definition(
  request_id,
  root_path,
  documents,
  current_file_content,
  current_file_path,
  current_line,
  current_char,
  ast
)
  definition(request_id, root_path, documents, current_file_content, current_file_path, current_line, current_char, ast)
end

---@param request_id integer
---@param request_params table
---@param current_file_content string,
---@param ast table
function server.rename(request_id, request_params, current_file_content, ast)
  rename(request_id, request_params, current_file_content, ast)
end

function server.shutdown()
  logger.log("LSP Server has been shutdown")
  response.shutdown()
end

return server
