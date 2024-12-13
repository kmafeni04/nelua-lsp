local logger = require("utils.logger")

---@param node table
---@param pos integer
---@param foundnodes table
---@return table?
---@return string? err
local function find_nodes_by_pos(node, pos, foundnodes)
  if type(node) ~= "table" then
    return nil, "Node passed to find_nodes_by_pos was not a table"
  end

  if node._astnode and node.pos and pos >= node.pos and node.endpos and pos <= node.endpos then
    foundnodes[#foundnodes + 1] = node
  end

  for i = 1, node.nargs or #node do
    find_nodes_by_pos(node[i], pos, foundnodes)
  end
  return foundnodes, nil
end

return find_nodes_by_pos