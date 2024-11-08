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
        hoverProvider = true,
      },
    },
    serverInfo = {
      name = "nelua_lsp",
      version = "0.0.1",
    },
  }
  logger.log(json.encode(intilaize_response))
  return json.encode(intilaize_response)
end

function response.shutdown()
  local shutdown_response = { result = {} }
  return json.encode(shutdown_response)
end

return response
