local json = require("libs.json")
local logger = require("utils.logger")

local rpc = {}

---@param msg table
---@return string? result
---@return string? err
function rpc.encode(msg)
  local ok, content = pcall(json.encode, msg)
  if ok then
    local result = ("Content-Length: %d\r\n\r\n%s"):format(#content, content)
    return result, nil
  else
    return nil, content
  end
end

---@param msg string
---@return table? obj
---@return string? err
function rpc.decode(msg)
  local ok, object = pcall(json.decode, msg)
  if ok then
    return object, nil
  else
    return nil, object
  end
end

return rpc
