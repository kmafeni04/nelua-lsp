local response = require("utils.response")

---@param request_id integer
return function(request_id)
  local initialize_response = response.initialize(request_id)
  io.stdout:write(initialize_response)
  io.flush()
end
