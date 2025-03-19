local logger = require("utils.logger")

---@param current_file_content string
---@param request_params table
---@return string
return function(current_file_content, request_params)
  ---@type string[]
  local lines = {}
  for line in string.gmatch(current_file_content .. "\n", "([^\n]-)\n") do
    logger.log(line)
    table.insert(lines, line)
  end

  for _, change in ipairs(request_params.contentChanges) do
    local start_line = change.range.start.line + 1
    local start_char = change.range.start.character + 1
    local end_line = change.range["end"].line + 1
    local end_char = change.range["end"].character + 1
    local text = change.text

    if lines[start_line] and start_line == end_line then
      lines[start_line] =
        table.concat({ lines[start_line]:sub(1, start_char - 1), text, lines[start_line]:sub(end_char) })
    else
      ---@type string[]
      local change_lines = {}
      for change_line in string.gmatch(text .. "\n", "([^\n]-)\n") do
        table.insert(change_lines, change_line)
      end

      local ci = 1
      local offset = 0
      for i = start_line, end_line do
        local current_line = i + offset
        if ci <= #change_lines then
          if current_line == start_line and lines[current_line] then
            lines[current_line] = table.concat({ lines[current_line]:sub(1, start_char - 1), change_lines[ci] })
          elseif lines[current_line] then
            table.insert(lines, current_line, change_lines[ci])
            offset = offset + 1
          else
            lines[current_line] = change_lines[ci]
            offset = offset + 1
          end
        elseif lines[current_line] then
          table.remove(lines, current_line)
          offset = offset - 1
        elseif ci == #lines then
          table.remove(lines, ci)
          offset = offset - 1
        end
        ci = ci + 1
      end
    end
  end

  current_file_content = table.concat(lines, "\n")
  logger.log(current_file_content)
  return current_file_content
end
