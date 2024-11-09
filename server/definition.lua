local response = require("utils.response")
local logger = require("utils.logger")
local find_node = require("utils.find_node")

---@param document string
---@param target_pos integer
---@return integer
---@return integer
local function find_definition_loc(document, target_pos)
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
  return line_num, start
end

---@param request_id integer
---@param documents table<string, string>
---@param current_file string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
return function(request_id, documents, current_file, current_file_path, current_line, current_char)
  local current_node, err = find_node(current_file, current_file_path, current_line, current_char)
  local locs = nil
  if current_node then
    locs = {}
    if current_node.is_Id and not current_node.attr.builtin then
      local target_node = current_node.attr.node
      local target_pos = target_node.pos
      local target_uri = "file://" .. target_node.src.name

      if documents[target_uri] then
        local line_num, start = find_definition_loc(documents[target_uri], target_pos)
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
      else
        ---@type string
        local document = io.open(target_node.src.name, "r"):read("a")
        local line_num, start = find_definition_loc(document, target_pos)
        logger.log(start)
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
      logger.log(target_uri)
    elseif current_node.is_call then
      logger.log(current_node.attr.calleesym.node)
    elseif current_node.is_DotIndex then
      -- logger.log(current_node.attr)
      -- local target_node = current_node[2].attr.node

      -- local target_pos = target_node.pos
      -- local target_uri = "file://" .. target_node.src.name
      -- -- logger.log(current_node[2].attr.node)
      -- if documents[target_uri] then
      --   local line_num, start = find_definition_loc(documents[target_uri], target_pos)
      --   ---@type Loc
      --   local loc = {
      --     uri = target_uri,
      --     range = {
      --       start = {
      --         line = line_num,
      --         character = start,
      --       },
      --       ["end"] = {
      --         line = line_num,
      --         character = start + #target_node.attr.name,
      --       },
      --     },
      --   }
      --   table.insert(locs, loc)
      -- else
      --   ---@type string
      --   local document = io.open(target_node.src.name, "r"):read("a")
      --   local line_num, start = find_definition_loc(document, target_pos)
      --   logger.log(start)
      --   ---@type Loc
      --   local loc = {
      --     uri = target_uri,
      --     range = {
      --       start = {
      --         line = line_num,
      --         character = start,
      --       },
      --       ["end"] = {
      --         line = line_num,
      --         character = start + #target_node.attr.name,
      --       },
      --     },
      --   }
      --   table.insert(locs, loc)
      -- end
    elseif current_node.attr.builtin then
      -- TODO
      -- for k, v in pairs(current_node.attr) do
      --   logger.log(tostring(k) .. "  k:" .. type(v))
      --   -- logger.log(tostring(v) .. "  v")
      -- end
    end
    ---@type Loc[]
  else
    logger.log(err)
  end
  local definition_response = response.definition(request_id, locs)
  io.write(definition_response)
  io.flush()
end
