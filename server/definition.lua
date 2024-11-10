local response = require("utils.response")
local logger = require("utils.logger")
local find_node = require("utils.find_node")

---@param documents table<string, string>
---@param target_node table
---@param locs Loc[]
local function add_new_definition(documents, target_node, locs)
  local target_pos = target_node.pos
  local target_uri = "file://" .. target_node.src.name

  ---@type string
  local document
  if documents[target_uri] then
    document = documents[target_uri]
  else
    document = io.open(target_node.src.name):read("a")
  end

  if not document then
    return
  end

  local line_num = 0
  local pos = 1
  for char in document:gmatch("([%s%S])") do
    if pos == target_pos then
      logger.log(pos)
      break
    end
    pos = pos + 1
    if char:match("[\r\n]") then
      line_num = line_num + 1
    end
  end
  local distance_to_prev_newline = 0
  for i = pos, 1, -1 do
    if document:sub(i, i):match("[\r\n]") then
      distance_to_prev_newline = i
      break
    end
  end
  local start = pos - distance_to_prev_newline - 1

  ---@type Loc
  local loc = {
    uri = target_uri,
    range = {
      start = {
        line = line_num,
        character = start,
      },
      ["end"] = {
        line = line_num,
        character = start + #target_node.attr.name,
      },
    },
  }
  table.insert(locs, loc)
end

---@param request_id integer
---@param documents table<string, string>
---@param current_file string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
return function(request_id, documents, current_file, current_file_path, current_line, current_char)
  -- logger.log(current_file_path)
  local current_node, err = find_node(current_file, current_file_path, current_line, current_char)
  local locs = nil
  if current_node then
    ---@type Loc[]
    locs = {}
    if current_node.is_IdDecl then
      local target_node = current_node.attr.node
      add_new_definition(documents, target_node, locs)
    elseif current_node.is_call then
      local target_node = current_node.attr.calleesym.node
      target_node.attr.name = current_node[1] .. " "
      add_new_definition(documents, target_node, locs)
    elseif current_node.is_Id and not current_node.attr.builtin then
      local target_node = current_node.attr.node
      add_new_definition(documents, target_node, locs)
    elseif current_node.is_DotIndex and current_node.attr.ftype and current_node.done and current_node.done.defnode then
      local target_node = current_node.done.defnode[2]
      target_node.attr.name = current_node[1] .. " "
      add_new_definition(documents, target_node, locs)
    elseif current_node.is_DotIndex then
      local target_node = current_node[2].attr.node
      add_new_definition(documents, target_node, locs)
    elseif current_node.attr.builtin then
      -- TODO
    end
  else
    logger.log(err)
  end
  local definition_response = response.definition(request_id, locs)
  io.write(definition_response)
  io.flush()
end
