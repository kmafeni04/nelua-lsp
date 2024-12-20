---@param pos integer
---@param current_file_content string
---@return integer line
---@return integer char
local function pos_to_line_and_char(pos, current_file_content)
  local s_line = 0
  local pos_at_line = 0
  local text = current_file_content:sub(1, pos)
  for line in text:gmatch("[^\r\n]*\r?\n") do
    pos_at_line = pos_at_line + #line
    s_line = s_line + 1
  end
  local s_char = pos - pos_at_line - 1
  return s_line, s_char
end

return pos_to_line_and_char
