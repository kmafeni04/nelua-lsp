--- Check if two things are equal
---@param a any
---@param b any
---@return boolean
local function equals(a, b)
  if type(a) == "table" and type(b) == "table" then
    if not next(a) and not next(b) then
      return true
    end
    if #a ~= #b then
      return false
    end
    for k1, v1 in pairs(a) do
      local val1 = v1
      local val2 = b[k1]
      if val2 == nil then
        return false
      end
      if type(val1) == "table" and type(val2) == "table" then
        return equals(val1, val2)
      end
      if val1 ~= val2 then
        return false
      end
    end
    for k2, v2 in pairs(b) do
      local val1 = v2
      local val2 = a[k2]
      if val2 == nil then
        return false
      end
      if type(val1) == "table" and type(val2) == "table" then
        return equals(val1, val2)
      end
      if val1 ~= val2 then
        return false
      end
    end
  elseif a ~= b then
    return false
  end
  return true
end

return equals
