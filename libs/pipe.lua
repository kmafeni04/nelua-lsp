---@alias PipeFunc fun(...: any): ...?
--[[
  Implements the "pipe operator" seen in functional languages, where the return of the previous function is the first parameter of the next

  Usage:
  ```lua
  local val = pipe("test", string.reverse, string.upper)
  print(val)
  --> Prints "TSET"
  ```
  
  If you would like to see what each function does to the parameter, you can set `dbg` to `true`
  ```lua
  local val = pipe("test", true, string.reverse, string.upper)
  print(val)
  --> Prints "Return of function 1:
  --          1: tset
  --          
  --          Return of function 2:
  --          1: TSET
  --          
  --          TSET"
  ```
  Anonymous functions can also be written directly into the sequence as long as they take at least one parameter and have a return
  ```lua
  local val = pipe("hello", function(x) return x .. " world" end, string.upper)
  print(val)
  --> Prints "HELLO WORLD"
  ```
]]
---@param param any
---@param dbg boolean
---@param ... PipeFunc
---@return ...?
---@overload fun(param: any, ...: PipeFunc): any
local pipe = function(param, dbg, ...)
  local unpack = table.unpack or unpack

  if type(param) == "function" then
    param = param()
  end
  local current_params = { param }
  local funcs = { ... }
  if type(dbg) == "function" then
    table.insert(funcs, 1, dbg)
  end
  for index, func in ipairs(funcs) do
    current_params = { func(unpack(current_params)) }
    if dbg == true then
      print("Return of function " .. index .. ":")
      for param_index, param_value in ipairs(current_params) do
        print(param_index .. ": " .. tostring(param_value))
      end
      print()
    end
  end
  return unpack(current_params)
end

return pipe
