local sstream = require("nelua.utils.sstream")

local server = require("utils.server")
local logger = require("utils.logger")
local find_nodes = require("utils.find_nodes")

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

---@param root_path string
---@param documents table<string, string>
---@param current_file_content string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
---@param ast table
return function(root_path, documents, current_file_content, current_file_path, current_line, current_char, ast)
  ---@type Loc[]
  local locs = {}
  local found_nodes, err = find_nodes(current_file_content, current_line, current_char, ast)
  if found_nodes then
    local current_node = found_nodes[#found_nodes]

    local previous_node
    if #found_nodes > 1 then
      previous_node = found_nodes[#found_nodes - 1]
    end
    if current_node.is_IdDecl then
      local target_node = current_node.attr.node
      add_new_definition(documents, target_node, locs)
    elseif current_node.is_String then
      if
        previous_node
        and previous_node.is_call
        and previous_node[2].is_Id
        and previous_node[2].attr.builtin
        and previous_node[2].attr.name == "require"
      then
        local ss = sstream()

        ---@type string
        local module_path = current_node.attr.value
        module_path = module_path:gsub("%.", "/")
        logger.log(root_path)
        logger.log(current_file_path)
        local current_relative_dir = current_file_path:sub(#root_path + 2):match("(.+/).*%.nelua")
        logger.log(current_relative_dir)
        if module_path:match("^/.*") then
          if current_relative_dir then
            ss:add(current_relative_dir)
          end
          module_path = module_path:sub(2)
        elseif not module_path:find("/") then
          if current_relative_dir then
            ss:add(current_relative_dir)
          end
        end
        ss:add(module_path)
        module_path = ss:tostring()
        logger.log(module_path)

        local git_files_prog, git_err = io.popen(
          "(cd $(git rev-parse --show-toplevel); git ls-files); (cd $(git rev-parse --show-toplevel); git ls-files --others)"
        )
        if git_files_prog then
          for file in git_files_prog:lines() do
            if file == module_path .. ".nelua" then
              local sss = sstream()
              sss:addmany("file://", root_path, "/", module_path, ".nelua")
              local go_to_path = sss:tostring()
              local loc = {
                uri = go_to_path,
                range = {
                  start = {
                    line = 0,
                    character = 0,
                  },
                  ["end"] = {
                    line = 0,
                    character = 1,
                  },
                },
              }
              table.insert(locs, loc)
            elseif file == module_path .. "/init.nelua" then
              local sss = sstream()
              sss:addmany("file://", root_path, "/", module_path, "/init.nelua")
              local go_to_path = sss:tostring()
              local loc = {
                uri = go_to_path,
                range = {
                  start = {
                    line = 0,
                    character = 0,
                  },
                  ["end"] = {
                    line = 0,
                    character = 1,
                  },
                },
              }
              table.insert(locs, loc)
            end
          end
        else
          logger.log(git_err)
        end
      end
    elseif current_node.is_Label then
      local target_node = current_node
      target_node.attr.name = "::" .. current_node[1] .. "::"
      add_new_definition(documents, target_node, locs)
    elseif current_node.is_Goto then
      local target_node = current_node.attr.label.node
      target_node.attr.name = "::" .. current_node[1] .. "::"
      add_new_definition(documents, target_node, locs)
    elseif current_node.is_call then
      local target_node = current_node.attr.calleesym.node
      if target_node then
        -- NOTE: location starts from . so add it to properly calculate name length
        target_node.attr.name = "." .. current_node[1]
        add_new_definition(documents, target_node, locs)
      end
    elseif current_node.is_Id and current_node.attr.node and not current_node.attr.builtin then
      local target_node = current_node.attr.node
      add_new_definition(documents, target_node, locs)
    elseif current_node.is_DotIndex and current_node.attr.ftype and current_node.done and current_node.done.defnode then
      local target_node = current_node.done.defnode[2]
      -- NOTE: location starts from . so add it to properly calculate name length
      target_node.attr.name = "." .. current_node[1]
      add_new_definition(documents, target_node, locs)
    elseif current_node.is_DotIndex then
      local target_node = current_node[2].attr.node
      add_new_definition(documents, target_node, locs)
    end
  else
    logger.log(err)
  end

  return locs
end
