local logger = require("utils.logger")
local analyze_ast = require("utils.analyze_ast")

---@param current_file string
---@param current_line integer
---@param current_char integer
local function find_pos(current_file, current_line, current_char)
  local i = 0
  local pos = 0
  for line in current_file:gmatch("[^\r\n]*\r?\n") do
    if i == current_line then
      pos = pos + current_char
      break
    end
    i = i + 1
    pos = pos + #line
  end
  return pos + 1
end

---@param node table
---@param pos integer
---@param foundnodes table
---@return table?
local function find_nodes_by_pos(node, pos, foundnodes)
  if type(node) ~= "table" then
    return nil
  end
  if node._astnode and node.pos and pos >= node.pos and node.endpos and pos < node.endpos then
    foundnodes[#foundnodes + 1] = node
  end
  for i = 1, node.nargs or #node do
    find_nodes_by_pos(node[i], pos, foundnodes)
  end
  return foundnodes
end

---@param current_file string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
---@return table? last_node
---@return table err
return function(current_file, current_file_path, current_line, current_char)
  local ast, err = analyze_ast(current_file, current_file_path)
  if ast then
    local pos = find_pos(current_file, current_line, current_char)

    local found_nodes = find_nodes_by_pos(ast, pos, {})
    if not found_nodes then
      err.message = "Could not find any nodes"
      return nil, err
    end
    local last_node = found_nodes[#found_nodes]
    return last_node, err
  else
    return nil, err
  end
end
