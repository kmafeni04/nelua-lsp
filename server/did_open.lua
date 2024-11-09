---@param current_file_path string
---@return string
return function(current_file_path)
  local current_file_prog = io.open(current_file_path)
  local current_file = ""
  if current_file_prog then
    current_file = current_file_prog:read("a")
  end
  return current_file
end
