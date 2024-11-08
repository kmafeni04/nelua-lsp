local response = require("utils.response")

---@param request_id integer
---@param current_file string
---@param current_line integer
---@param current_char integer
return function(request_id, current_file, current_line, current_char)
  local content = "hello"
  local hover_response = response.hover(request_id, content)
  io.write(hover_response)
  io.flush()
end
