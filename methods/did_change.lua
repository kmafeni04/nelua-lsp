local logger = require("utils.logger")

---@param text string
---@return table
local function text_to_lines(text)
  local lines = {}
  for line in string.gmatch(text .. "\n", "(.-)\n") do
    table.insert(lines, line)
  end
  return lines
end

-- Get text before specified character position
---@param text string
---@param pos integer
---@return string
local function text_before(text, pos)
  if not text then
    return ""
  end

  if pos == 0 then
    return ""
  elseif pos >= #text then
    return text
  else
    return string.sub(text, 1, pos)
  end
end

-- Get text after specified character position
---@param text string
---@param pos integer
---@return string
local function text_after(text, pos)
  if not text then
    return ""
  end

  if pos == 0 then
    return text
  elseif pos >= #text then
    return ""
  else
    return string.sub(text, pos + 1)
  end
end

-- Apply a single change to document lines
---@param lines table
---@param change table
---@return table
local function apply_change(lines, change)
  -- Convert zero-based LSP positions to one-based Lua indices
  local start_line = change.range["start"].line + 1
  local start_char = change.range["start"].character
  local end_line = change.range["end"].line + 1
  local end_char = change.range["end"].character

  -- Split new text into lines
  local new_lines = text_to_lines(change.text)
  local new_end_line = start_line + #new_lines - 1

  -- Get the preserved parts of the changed lines
  local left = text_before(lines[start_line], start_char)
  local right = text_after(lines[end_line], end_char)

  -- Ensure the document has enough lines
  if end_line > #lines then
    for i = #lines + 1, end_line do
      lines[i] = ""
    end
  end

  -- Adjust document line count if needed
  local line_count = #new_lines - (end_line - start_line + 1)
  if line_count ~= 0 then
    -- Move lines down if inserting, up if deleting
    table.move(lines, end_line, #lines, end_line + line_count)

    -- Remove excess lines if removing text
    if line_count < 0 then
      for i = #lines, #lines + line_count + 1, -1 do
        lines[i] = nil
      end
    end
  end

  -- Update the affected lines
  if start_line == new_end_line then
    -- Single line change
    lines[start_line] = left .. new_lines[1] .. right
  else
    -- Multi-line change
    lines[start_line] = left .. new_lines[1]
    lines[new_end_line] = new_lines[#new_lines] .. right

    -- Update lines in between
    for i = 2, #new_lines - 1 do
      lines[start_line + i - 1] = new_lines[i]
    end
  end

  return lines
end

---@param request_params table
---@param current_file_content string
return function(request_params, current_file_content)
  local text = current_file_content
  local lines = nil
  local changes = request_params.contentChanges

  for _, change in ipairs(changes) do
    if change.range then
      -- Incremental change - update specific parts of the document
      lines = lines or text_to_lines(text)
      lines = apply_change(lines, change)
    else
      -- Full document change - replace entire content
      lines = nil
      text = change.text
    end
  end

  -- Reconstruct full text if we have lines
  if lines then
    text = table.concat(lines, "\n")
  end

  return text
end
