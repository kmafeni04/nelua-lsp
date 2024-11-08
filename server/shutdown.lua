local response = require("utils.response")
local logger = require("utils.logger")

return function()
  logger.log("LSP Server has been shutdown")
  local shutdown_response = response.shutdown()
  io.write(shutdown_response)
  io.flush()
end
