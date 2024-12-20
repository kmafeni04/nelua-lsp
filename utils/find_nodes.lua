local logger = require("utils.logger")
local find_pos = require("utils.find_pos")
local find_nodes_by_pos = require("utils.find_node_by_pos")

---@param current_file_content string
---@param current_line integer
---@param current_char integer
---@param ast table
---@return table? found_nodes
---@return string? err
return function(current_file_content, current_line, current_char, ast)
  if ast then
    local pos = find_pos(current_file_content, current_line, current_char)
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
