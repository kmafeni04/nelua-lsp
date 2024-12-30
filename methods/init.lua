local logger = require("utils.logger")
local server = require("utils.server")

local did_change = require("methods.did_change")
local diagnostic = require("methods.diagnostic")
local completion = require("methods.completion")
local hover = require("methods.hover")
local definition = require("methods.definition")
local rename = require("methods.rename")

local methods = {}

---@param request_id integer
function methods.initialize(request_id)
  local intilaize_result = {
    capabilities = {
      textDocumentSync = 2,
      completionProvider = { triggerCharacters = { ".", ":", "@", "*", "&", "$" } },
      hoverProvider = true,
      renameProvider = true,
      definitionProvider = true,
    },
  }
  if not server.send_response(request_id, intilaize_result) then
    server.send_error(request_id, server.LspErrorCode.ServerNotInitialized, "Failed to initialize server")
  end
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
---@return Diagnsotic[]
function methods.diagnostic(current_file_content, current_file_path, current_uri)
  return diagnostic(current_file_content, current_file_path, current_uri)
end

---@param current_file_content string
---@param request_params table
---@return string
function methods.did_change(current_file_content, request_params)
  return did_change(current_file_content, request_params)
end

---@param request_id integer
---@param request_params table
---@param documents table<string, string>
---@param current_file_path string
---@param current_uri string
---@param current_file_content string
---@param ast_cache table<string, table>
function methods.completion(
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
function methods.hover(request_id, current_file_content, current_file_path, current_line, current_char, ast)
  return hover(request_id, current_file_content, current_file_path, current_line, current_char, ast)
end

---@param request_id integer
---@param root_path string
---@param documents table<string, string>
---@param current_file_content string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
---@param ast? table
function methods.definition(
  request_id,
  root_path,
  documents,
  current_file_content,
  current_file_path,
  current_line,
  current_char,
  ast
)
  return definition(
    request_id,
    root_path,
    documents,
    current_file_content,
    current_file_path,
    current_line,
    current_char,
    ast
  )
end

---@param request_id integer
---@param request_params table
---@param current_file_content string,
---@param ast table
function methods.rename(request_id, request_params, current_file_content, ast)
  return rename(request_id, request_params, current_file_content, ast)
end

function methods.shutdown()
  logger.log("LSP Server has been shutdown")
  server.send_response(nil, {})
end

return methods
