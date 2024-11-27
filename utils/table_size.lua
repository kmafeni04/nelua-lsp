--- Returns the total number of top level elements in a table
---@param t table
---@return integer
return function(t)
  local count = 0
  for k, v in pairs(t) do
    count = count + 1
  end
  return count
end
