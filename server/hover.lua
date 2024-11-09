local sstream = require("nelua.utils.sstream")

local switch = require("lib.switch")

local find_node = require("utils.find_node")
local logger = require("utils.logger")
local response = require("utils.response")

---@param request_id integer
---@param documents table<string, string>
---@param current_uri string
---@param current_file string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
return function(request_id, documents, current_uri, current_file, current_file_path, current_line, current_char)
  current_file = current_file or documents[current_uri]
  local content = ""
  local ss = sstream()
  local current_node = find_node(current_file, current_file_path, current_line, current_char)
  if not current_node then
    return nil
  end

  -- for k, v in pairs(lastnode) do
  --   logger.log(tostring(k) .. "  k")
  --   logger.log(tostring(v) .. "  v")
  -- end
  -- logger.log(ast)
  -- logger.log(assert(found_nodes)[#found_nodes - 1])

  if current_node.attr.builtin then
    ss:add("```nelua\nType: ")
    switch(current_node.attr.name, {
      ["require"] = function()
        ss:add("function(modname: string)")
      end,
      ["print"] = function()
        ss:add("polyfunction(varargs): void")
      end,
      ["panic"] = function()
        ss:add("function(message: string): void")
      end,
      ["error"] = function()
        ss:add("function(message: string): void")
      end,
      ["assert"] = function()
        ss:add("polyfunction(v: auto, message: facultative(string)): void")
      end,
      ["check"] = function()
        ss:add("polyfunction(cond: boolean, message: facultative(string)): void")
      end,
      ["likely"] = function()
        ss:add("function(cond: boolean): boolean")
      end,
      ["unlikely"] = function()
        ss:add("function(cond: boolean): boolean")
      end,
    })
    ss:add("\n```")

    content = ss:tostring("\n```")
  elseif current_node.attr.name then
    ss:addmany(current_node.attr.name, "\n```nelua\n", "Type: ", current_node.attr.type, "\n```")
    content = ss:tostring()
  elseif current_node.attr.type and tostring(current_node.attr.type) == "string" and current_node.attr.value then
    ss:addmany("```nelua\n", #current_node.attr.value, " bytes", "\n```")
    content = ss:tostring()
  elseif current_node.attr.type and tostring(current_node.attr.type) == "string" and current_node.attr.ismethod then
    local node_name, node_type = tostring(current_node.attr.calleesym):match("^(.-):%s*(.+)")
    ss:addmany(node_name, "\n```nelua\n", "Type: ", node_type, "\n```")
    content = ss:tostring()
  elseif current_node.attr.dotfieldname then
    local parent_name = ""
    if current_node[2].attr.name then
      parent_name = current_node[2].attr.name .. "."
    elseif current_node[2].attr.dotfieldname then
      parent_name = current_node[2].attr.dotfieldname .. "."
    elseif not current_node[2].attr.name and not current_node[2].attr.dotfieldname and current_node[2].attr.type then
      parent_name = tostring(current_node[2].attr.type) .. "."
    end
    ss:addmany(parent_name, current_node.attr.dotfieldname, "\n```nelua\n", "Type: ", current_node.attr.type, "\n```")
    content = ss:tostring()
  elseif not current_node.attr.name and current_node.attr.value then
    ss:addmany("```nelua\n", "Type: ", current_node.attr.value, "\n```")
    content = ss:tostring()
  end
  local hover_response = response.hover(request_id, content)
  io.write(hover_response)
  io.flush()
end
