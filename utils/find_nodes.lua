local logger = require("utils.logger")
local find_pos = require("utils.find_pos")

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

  -- set nodes endpos to parents if it has a parent
  -- if node and node.attr and node.attr.scope and node.attr.scope.parent then
  --   local parent_node = node.attr.scope.parent.node
  --   if parent_node.is_FuncDef then
  --     node.endpos = parent_node.endpos
  --   end
  -- end
  if node._astnode and node.pos and pos >= node.pos and node.endpos and pos <= node.endpos then
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
          ("%s:%d: find_nodes_by_pos returned and empty table"):format(
            debug.getinfo(1).source,
            debug.getinfo(1).currentline
          )
      end
    else
      return nil, err
    end
  end
end
