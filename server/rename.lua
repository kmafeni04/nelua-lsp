local response = require("utils.response")
local logger = require("utils.logger")
local find_nodes = require("utils.find_nodes")
local pos_to_line_and_char = require("utils.pos_to_line_char")

---@param node table
---@param pos integer
---@param foundnodes table
---@return table?
---@return string? err
local function find_nodes_in_scope_node(node, pos, foundnodes)
  if type(node) ~= "table" then
    return nil, "Node passed to find_nodes_in_scope_node was not a table"
  end

  local parent_node
  if node and node.attr and node.attr.scope and node.attr.scope.parent then
    parent_node = node.attr.scope.parent.node
  end

  if
    node._astnode
    and (
      (node.pos and node.pos <= pos and node.endpos and node.endpos >= pos)
      or (
        parent_node
        and parent_node.pos
        and parent_node.pos <= pos
        and parent_node.endpos
        and parent_node.endpos >= pos
      )
    )
  then
    foundnodes[#foundnodes + 1] = node
  end

  for i = 1, node.nargs or #node do
    find_nodes_in_scope_node(node[i], pos, foundnodes)
  end
  return foundnodes, nil
end

---@param request_id integer
---@param request_params table
---@param current_file string,
---@param ast table
return function(request_id, request_params, current_file, ast)
  local changes = {
    [request_params.textDocument.uri] = {},
  }
  ---@type Position
  local position = request_params.position
  local found_nodes, err = find_nodes(current_file, position.line, position.character, ast)
  if found_nodes then
    local current_node = found_nodes[#found_nodes]
    if current_node.is_Id or current_node.is_IdDecl then
      local scope_node = current_node.attr.scope.node
      local scope_nodes, err = find_nodes_in_scope_node(scope_node, scope_node.endpos, {})
      if scope_nodes then
        for _, node in ipairs(scope_nodes) do
          if
            (node.is_Id or node.is_IdDecl)
            and node.pos
            and node.attr
            and node.attr.name
            and node.attr.name == current_node.attr.name
            and node.attr.type
            and tostring(node.attr.type) == tostring(current_node.attr.type)
          then
            local s_line, s_char = pos_to_line_and_char(node.pos, current_file)
            table.insert(changes[request_params.textDocument.uri], {
              ---@type Range
              range = {
                start = {
                  line = s_line,
                  character = s_char,
                },
                ["end"] = {
                  line = s_line,
                  character = s_char + #current_node.attr.name,
                },
              },
              newText = request_params.newName,
            })
          end
        end
      else
        logger.log(err)
      end
    end
  else
    logger.log(err)
  end
  return response.rename(request_id, changes)
end
