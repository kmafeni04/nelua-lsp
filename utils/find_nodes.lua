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
---@return string? err
local function find_nodes_by_pos(node, pos, foundnodes)
  if type(node) ~= "table" then
    return nil, "Node passed to find_nodes_by_pos was not a table"
  end
  -- if
  --   node._astnode
  --   and node.pos
  --   and pos >= node.pos
  --   and node[1]
  --   and type(node[1]) == "string"
  --   and pos <= node.pos + #node[1]
  -- then
  if node._astnode and node.pos and pos >= node.pos and node.endpos and pos < node.endpos then
    -- logger.log(node._astnode)
    foundnodes[#foundnodes + 1] = node
  end
  for i = 1, node.nargs or #node do
    find_nodes_by_pos(node[i], pos, foundnodes)
  end
  return foundnodes, nil
end

---@param current_file string
---@param current_line integer
---@param current_char integer
---@param ast? table
---@return table? found_nodes
---@return string? err
return function(current_file, current_line, current_char, ast)
  if ast then
    local pos = find_pos(current_file, current_line, current_char)
    local found_nodes, err = find_nodes_by_pos(ast, pos, {})
    if found_nodes then
      if #found_nodes > 0 then
        return found_nodes, nil
      else
        return nil,
          debug.getinfo(2).source
            .. ":"
            .. debug.getinfo(2).currentline
            .. ": find_nodes_by_pos returned and empty table"
      end
    else
      return nil, err
    end
  end
end
