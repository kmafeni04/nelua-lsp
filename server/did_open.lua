---@param current_file_path string
---@return string
return function(current_file_path)
  local current_file = io.open(current_file_path):read("a")
  return current_file
end
