local logger = require("utils.logger")

local initialize = require("server.initialize")
local did_open = require("server.did_open")
local diagnostic = require("server.diagnostic")
local did_change = require("server.did_change")
local hover = require("server.hover")
local shutdown = require("server.shutdown")
local server = {}

---@param request_id integer
function server.initialize(request_id)
  initialize(request_id)
end

---@param current_file_path string
function server.did_open(current_file_path)
  return did_open(current_file_path)
end

---@param documents table<string, string>
---@param current_file string
---@param current_file_path string
---@param current_uri string
---@return boolean
function server.diagnostic(documents, current_file, current_file_path, current_uri)
  return diagnostic(documents, current_file, current_file_path, current_uri)
end

---@param documents table<string, string>
---@param request_params table
---@param current_uri string
---@return string
function server.did_change(documents, request_params, current_uri)
  return did_change(documents, request_params, current_uri)
end
---@param request_id integer
---@param documents table<string, string>
---@param current_uri string
---@param current_file string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
function server.hover(request_id, documents, current_uri, current_file, current_file_path, current_line, current_char)
  hover(request_id, documents, current_uri, current_file, current_file_path, current_line, current_char)
end

function server.shutdown()
  shutdown()
end

return server
