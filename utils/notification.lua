local rpc = require("utils.rpc")
local logger = require("utils.logger")

local notification = {}

---@param current_uri string
---@param line integer
---@param start_char integer
---@param end_char integer
---@param severity integer
---@param msg string
---@param clear boolean
function notification.diagnostic(current_uri, line, start_char, end_char, severity, msg, clear)
  local diagnostic_notif = {
    jsonrpc = "2.0",
    method = "textDocument/publishDiagnostics",
    params = {
      uri = current_uri,
      diagnostics = {
        {
          range = {
            start = { line = line, character = start_char },
            ["end"] = { line = line, character = end_char },
          },
          message = msg,
          severity = severity,
        },
      },
    },
  }
  if clear then
    diagnostic_notif.params.diagnostics[1] = nil
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
