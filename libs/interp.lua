--[[
  Replaces `{{VAR}}` in the provided string with the value of it's corresponding variable if present
  Usage:
  ```lua
  local val = "hello world"
  print(interp("The value of val is {{val}}"))
  --> Prints "The value of val is hello world"
  ```
  if the variable isn't present:
  ```lua
  print(interp("The {{no_var}} variable isn't present"))
  --> Prints "The {{no_var}} variable isn't present"
  ```
  Works with expressions and table fields
  ```lua
  local tbl = { a = 1 }
  print(interp("The value of tbl.a + 1 is {{tbl.a + 1}}"))
  --> Prints "The value of tbl.a + 1 is 2"
  ```
]]
---@param str string
---@return string
local function interp(str)
  local variables = {}
  local idx = 1
  repeat
    local key, value = debug.getlocal(2, idx)
    if key ~= nil then
      variables[key] = value
    end
    idx = idx + 1
  until key == nil

  for key, value in pairs(_G) do
    variables[key] = value
  end

  local function eval(expr)
    local func
    if _VERSION == "Lua 5.1" then
      func, _ = loadstring("return " .. expr)
      if func then
        setfenv(func, variables)
      end
    else
      func, _ = load("return " .. expr, nil, nil, variables)
    end
    if func then
      local success, result = pcall(func)
      if success and result then
        return tostring(result)
      end
    else
      return "{{" .. expr .. "}}"
    end
  end

  local new_str = str:gsub("{{(.-)}}", function(expr)
    return eval(expr:match("^%s*(.-)%s*$"))
  end)

  return new_str
end

return interp
