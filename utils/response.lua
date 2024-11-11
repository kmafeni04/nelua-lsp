local logger = require("utils.logger")

local json = require("utils.json")

local response = {}

---@param request_id integer
function response.initialize(request_id)
  local intilaize_response = {
    jsonrpc = "2.0",
    id = request_id,
    result = {
      capabilities = {
        textDocumentSync = 1,
        hoverProvider = true,
        definitionProvider = true,
      },
    },
    serverInfo = {
      name = "nelua_lsp",
      version = "0.0.1",
    },
  }
  io.write(json.encode(intilaize_response))
  io.flush()
end

---@param request_id integer
---@param content string
function response.hover(request_id, content)
  local hover_response = {
    jsonrpc = "2.0",
    id = request_id,
    result = {
      contents = content,
    },
  }
  io.write(json.encode(hover_response))
  io.flush()
end

---@class Position
---@field line integer
---@field character integer

---@class Range
---@field start Position
---@field end Position

---@class Loc
---@field uri string
---@field range Range

---@param request_id integer
---@param locs? Loc[]
function response.definition(request_id, locs)
  local definition_response = {
    jsonrpc = "2.0",
    id = request_id,
    result = locs or {},
    error = "No definition found",
  }

  io.write(json.encode(definition_response))
  io.flush()
end

function response.shutdown()
  local shutdown_response = { result = {} }

  io.write(json.encode(shutdown_response))
  io.flush()
end

return response
