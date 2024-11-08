local logger = require("utils.logger")

local initialize = require("server.initialize")
local did_open = require("server.did_open")
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

---@param request_id integer
---@param current_file string
---@param current_line integer
---@param current_char integer
function server.hover(request_id, current_file, current_line, current_char)
  hover(request_id, current_file, current_line, current_char)
end

function server.shutdown()
  shutdown()
end

return server
