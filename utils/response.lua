local logger = require("utils.logger")

local json = require("utils.json")

local response = {}

---@param request_id integer
---@return string?
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
  return json.encode(intilaize_response)
end

---@param request_id integer
---@param content string
---@return string?
function response.hover(request_id, content)
  local hover_response = {
    jsonrpc = "2.0",
    id = request_id,
    result = {
      contents = content,
    },
  }
  return json.encode(hover_response)
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

  return json.encode(definition_response)
end

---@return string?
function response.shutdown()
  local shutdown_response = { result = {} }
  return json.encode(shutdown_response)
end

return response
