local logger = require("utils.logger")
local response = require("utils.response")

local diagnostic = require("server.diagnostic")
local completion = require("server.completion")
local hover = require("server.hover")
local definition = require("server.definition")

local server = {}

---@param request_id integer
function server.initialize(request_id)
  response.initialize(request_id)
end

---@param current_file_path string
---@return string?
-- function server.did_open(current_file_path)
--   local current_file_prog = io.open(current_file_path)
--   local current_file
--   if current_file_prog then
--     current_file = current_file_prog:read("a")
--   end
--   return current_file
-- end

---@param current_file string
---@param current_file_path string
---@param current_uri string
---@return table? ast
function server.diagnostic(current_file, current_file_path, current_uri)
  return diagnostic(current_file, current_file_path, current_uri)
end

---@param documents table<string, string>
---@param current_uri string
---@param request_params table
---@return string
function server.did_change(documents, current_uri, request_params)
  local current_file = request_params.contentChanges[1].text
  return current_file
end

---@param request_id integer
---@param request_params table
---@param current_file_path string
---@param current_uri string
---@param current_file string
---@param ast_cache table<string, table>
function server.completion(request_id, request_params, current_uri, current_file_path, current_file, ast_cache)
  return completion(request_id, request_params, current_uri, current_file_path, current_file, ast_cache)
end

---@param request_id integer
---@param current_file string
---@param current_line integer
---@param current_char integer
---@param ast? table
function server.hover(request_id, current_file, current_line, current_char, ast)
  hover(request_id, current_file, current_line, current_char, ast)
end

---@param request_id integer
---@param root_path string
---@param documents table<string, string>
---@param current_file string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
---@param ast? table
function server.definition(
  request_id,
  root_path,
  documents,
  current_file,
  current_file_path,
  current_line,
  current_char,
  ast
)
  definition(request_id, root_path, documents, current_file, current_file_path, current_line, current_char, ast)
end

function server.shutdown()
  logger.log("LSP Server has been shutdown")
  response.shutdown()
end

return server
