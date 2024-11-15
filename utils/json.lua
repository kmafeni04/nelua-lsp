local rxi_json = require("lib.rxi_json")
local logger = require("utils.logger")

local json = {}

---@param msg table
---@return string? result
---@return string? err
function json.encode(msg)
  local ok, content = pcall(rxi_json.encode, msg)
  if ok then
    local result = "Content-Length: " .. #content .. "\r\n\r\n" .. content
    return result, nil
  else
    return nil, content
  end
end

---@param msg string
---@return table? obj
---@return string? err
function json.decode(msg)
  local ok, object = pcall(rxi_json.decode, msg)
  if ok then
    return object, nil
  else
    return nil, object
  end
end

return json
