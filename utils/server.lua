local logger = require("utils.logger")
local rpc = require("utils.rpc")

---@class Server
local server = {}

---@enum LspErrorCode
local LspErrorCode = {
  ParseError = -32700,
  InvalidRequest = -32600,
  MethodNotFound = -32601,
  InvalidParams = -32602,
  InternalError = -32603,
  serverErrorStart = -32099,
  serverErrorEnd = -32000,
  ServerNotInitialized = -32002,
  UnknownErrorCode = -32001,
  RequestFailed = -32803,
}

function server.send_response(request_id, result)
  local response = {
    jsonrpc = "2.0",
    id = request_id,
    result = result,
  }

  local encoded_msg, err = rpc.encode(response)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
  else
    logger.log(err)
  end
end

---@param request_id integer
---@param code LspErrorCode
---@param msg string
function server.send_error(request_id, code, msg)
  local error = {
    jsonrpc = "2.0",
    id = request_id,
    error = {
      code = code,
      message = msg,
    },
  }

  local encoded_msg, err = rpc.encode(error)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
  else
    logger.log(err)
  end
end

return server
