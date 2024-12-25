local logger = require("utils.logger")
local rpc = require("utils.rpc")

---@class Server
local server = {}

---@enum LspErrorCode
server.LspErrorCode = {
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

---@param request_id integer?
---@param result table
---@return boolean
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
    return true
  else
    logger.log(err)
    return false
  end
end

---@param method string
---@param params table
function server.send_notification(method, params)
  local notif = {
    jsonrpc = "2.0",
    method = method,
    params = params,
  }
  local encoded_msg, err = rpc.encode(notif)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
    return true
  else
    logger.log(err)
    return false
  end
end

---@param request_id integer
---@param code LspErrorCode
---@param msg string
function server.send_error(request_id, code, msg)
  local err = {
    jsonrpc = "2.0",
    id = request_id,
    error = {
      code = code,
      message = msg,
    },
  }

  local encoded_msg, encoded_err = rpc.encode(err)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
    return true
  else
    logger.log(encoded_err)
    return false
  end
end

return server
