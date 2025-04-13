local logger = require("utils.logger")

---@param request_params table
---@param current_file_content string
---@return string
return function(request_params, current_file_content)
  ---@param text string
  local function split_lines(text)
    local lines = {}
    for line in string.gmatch(text .. "\n", "([^\n]-)\n") do
      table.insert(lines, line)
    end
    return lines
  end

  ---@param lines table
  ---@param change table
  local function apply_change(lines, change)
    local s_line = change.range.start.line + 1
    local s_char = change.range.start.character + 1
    local e_line = change.range["end"].line + 1
    local e_char = change.range["end"].character + 1

    -- Handle pure insertions
    if s_line == e_line and s_char == e_char then
      local line = lines[s_line] or ""
      lines[s_line] = line:sub(1, s_char - 1) .. change.text .. line:sub(s_char)
      return
    end

    if s_line > #lines + 1 then
      return
    end

    while #lines < s_line do
      table.insert(lines, "")
    end

    local new_lines = split_lines(change.text)
    local head = lines[s_line] and lines[s_line]:sub(1, s_char - 1) or ""
    local tail = lines[e_line] and lines[e_line]:sub(e_char + 1) or ""

    local replacement = {}
    if #new_lines == 1 then
      table.insert(replacement, head .. new_lines[1] .. tail)
    else
      table.insert(replacement, head .. new_lines[1])
      for i = 2, #new_lines - 1 do
        table.insert(replacement, new_lines[i])
      end
      table.insert(replacement, new_lines[#new_lines] .. tail)
    end

    for _ = s_line, math.min(e_line, #lines) do
      table.remove(lines, s_line)
    end

    for i = #replacement, 1, -1 do
      table.insert(lines, s_line, replacement[i])
    end
  end

  -- Split the file into lines
  local lines = split_lines(current_file_content)

  -- Apply each text change
  for _, change in ipairs(request_params.contentChanges) do
    apply_change(lines, change)
  end

  -- Rejoin the lines into final content
  current_file_content = next(lines) and table.concat(lines, "\n") or current_file_content
  logger.log(current_file_content)
  return current_file_content
end
