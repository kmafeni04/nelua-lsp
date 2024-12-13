local switch = require("lib.switch")

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
  elseif node[2] and type(node[2]) == "table" and node[2].attr and node[2].attr.scope and node[2].attr.scope.node then
    parent_node = node[2].attr.scope.node
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
    switch(true, {
      [(current_node.is_Id or current_node.is_IdDecl) or false] = function()
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
      end,
      [current_node.is_DotIndex or false] = function()
        if current_node.attr.metafunc then
          local scope_node = current_node.attr.scope.node
          local scope_nodes, err = find_nodes_in_scope_node(scope_node, scope_node.endpos, {})
          if scope_nodes then
            for _, node in ipairs(scope_nodes) do
              if node.is_DotIndex and node[1] == current_node[1] then
                local s_line, s_char = pos_to_line_and_char(node.pos + 1, current_file)
                table.insert(changes[request_params.textDocument.uri], {
                  ---@type Range
                  range = {
                    start = {
                      line = s_line,
                      character = s_char,
                    },
                    ["end"] = {
                      line = s_line,
                      character = s_char + #node[1],
                    },
                  },
                  newText = request_params.newName,
                })
              end
            end
          else
            logger.log(err)
          end
        elseif current_node[2] and type(current_node[2]) == "table" then
          local parent_node = current_node[2]
          local scope_node = parent_node.attr.scope.node
          local scope_nodes, err = find_nodes_in_scope_node(scope_node, scope_node.endpos, {})
          if parent_node.attr.type.is_record or parent_node.attr.type.is_union then
            if scope_nodes then
              for _, node in ipairs(scope_nodes) do
                if node.is_DotIndex and node[1] == current_node[1] then
                  local s_line, s_char = pos_to_line_and_char(node.pos + 1, current_file)
                  table.insert(changes[request_params.textDocument.uri], {
                    ---@type Range
                    range = {
                      start = {
                        line = s_line,
                        character = s_char,
                      },
                      ["end"] = {
                        line = s_line,
                        character = s_char + #node[1],
                      },
                    },
                    newText = request_params.newName,
                  })
                end
              end
            else
              logger.log(err)
            end
            for _, node_fields in ipairs(parent_node.attr.type.node) do
              if type(node_fields) == "table" then
                if node_fields[1] == current_node[1] then
                  local s_line, s_char = pos_to_line_and_char(node_fields.pos, current_file)
                  table.insert(changes[request_params.textDocument.uri], {
                    ---@type Range
                    range = {
                      start = {
                        line = s_line,
                        character = s_char,
                      },
                      ["end"] = {
                        line = s_line,
                        character = s_char + #current_node[1],
                      },
                    },
                    newText = request_params.newName,
                  })
                  break
                end
              end
            end
          elseif parent_node.attr.value and parent_node.attr.value.is_enum then
            if scope_nodes then
              for _, node in ipairs(scope_nodes) do
                if node.is_DotIndex and node[1] == current_node[1] then
                  local s_line, s_char = pos_to_line_and_char(node.pos + 1, current_file)
                  table.insert(changes[request_params.textDocument.uri], {
                    ---@type Range
                    range = {
                      start = {
                        line = s_line,
                        character = s_char,
                      },
                      ["end"] = {
                        line = s_line,
                        character = s_char + #node[1],
                      },
                    },
                    newText = request_params.newName,
                  })
                end
              end
            else
              logger.log(err)
            end
            for _, node_fields in ipairs(parent_node.attr.value.node[2]) do
              if type(node_fields) == "table" then
                local s_line, s_char = pos_to_line_and_char(node_fields.pos, current_file)
                table.insert(changes[request_params.textDocument.uri], {
                  ---@type Range
                  range = {
                    start = {
                      line = s_line,
                      character = s_char,
                    },
                    ["end"] = {
                      line = s_line,
                      character = s_char + #current_node[1],
                    },
                  },
                  newText = request_params.newName,
                })
                break
              end
            end
          end
        end
      end,
    })
  else
    logger.log(err)
  end
  return response.rename(request_id, changes)
end
