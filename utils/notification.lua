local rpc = require("utils.rpc")
local logger = require("utils.logger")

local notification = {}

---@param current_uri string
---@param diagnostics table
---@param clear boolean
function notification.diagnostic(current_uri, diagnostics, clear)
  local diagnostic_notif = {
    jsonrpc = "2.0",
    method = "textDocument/publishDiagnostics",
    params = {
      uri = current_uri,
      diagnostics = diagnostics,
    },
  }
  if clear then
    diagnostic_notif.params.diagnostics = {}
  end
  local encoded_notif, err = rpc.encode(diagnostic_notif)
  if encoded_notif then
    io.write(encoded_notif)
    io.flush()
  else
    logger.log(err)
  end
end

return notification
