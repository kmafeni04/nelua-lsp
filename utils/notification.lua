local json = require("utils.json")
local logger = require("utils.logger")

local notification = {}

---@param current_uri string
---@param line integer
---@param start_char integer
---@param end_char integer
---@param severity integer
---@param msg string
---@param clear boolean
---@return string?
function notification.diagnostic(current_uri, line, start_char, end_char, severity, msg, clear)
  local diagnostic_response = {
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
    diagnostic_response.params.diagnostics[1] = nil
  end
  return json.encode(diagnostic_response)
end

return notification
