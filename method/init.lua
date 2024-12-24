local logger = require("utils.logger")
local response = require("utils.response")
local server = require("utils.server")

local did_change = require("method.did_change")
local diagnostic = require("method.diagnostic")
local completion = require("method.completion")
local hover = require("method.hover")
local definition = require("method.definition")
local rename = require("method.rename")

local method = {}

---@param request_id integer
function method.initialize(request_id)
  local intilaize_result = {
    capabilities = {
      textDocumentSync = 2,
      completionProvider = { triggerCharacters = { ".", ":", "@", "*", "&", "$" } },
      hoverProvider = true,
      renameProvider = true,
      definitionProvider = true,
    },
  }
  server.send_response(request_id, intilaize_result)
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
function method.diagnostic(current_file_content, current_file_path, current_uri)
  return diagnostic(current_file_content, current_file_path, current_uri)
end

---@param current_file_content string
---@param request_params table
---@return string
function method.did_change(current_file_content, request_params)
  return did_change(current_file_content, request_params)
end

---@param request_id integer
---@param request_params table
---@param documents table<string, string>
---@param current_file_path string
---@param current_uri string
---@param current_file_content string
---@param ast_cache table<string, table>
function method.completion(
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
function method.hover(request_id, current_file_content, current_file_path, current_line, current_char, ast)
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
function method.definition(
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
function method.rename(request_id, request_params, current_file_content, ast)
  rename(request_id, request_params, current_file_content, ast)
end

function method.shutdown()
  logger.log("LSP Server has been shutdown")
  response.shutdown()
end

return method
