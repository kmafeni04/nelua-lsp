local sstream = require("nelua.utils.sstream")

local switch = require("lib.switch")

local find_node = require("utils.find_node")
local logger = require("utils.logger")
local response = require("utils.response")

---@param request_id integer
---@param current_file string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
return function(request_id, current_file, current_file_path, current_line, current_char)
  local content = ""
  local ss = sstream()
  local current_node = find_node(current_file, current_file_path, current_line, current_char)
  if not current_node then
    return
  end

  -- for k, v in pairs(current_node) do
  --   logger.log(tostring(k) .. "  k")
  --   logger.log(tostring(v) .. "  v")
  -- end
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
  elseif current_node.is_Id or current_node.is_IdDecl then
    ss:addmany(current_node.attr.name, "\n```nelua\n", "Type: ", current_node.attr.type)
    if current_node.attr.value then
      ss:add(" = ")
      if tostring(current_node.attr.type) == "string" then
        if current_node.attr.value:match("[\r\n]") then
          ss:addmany("[[", current_node.attr.value, "]]")
        else
          ss:addmany('"', current_node.attr.value, '"')
        end
      else
        ss:add(current_node.attr.value)
      end
    end
    ss:add("\n```")
    content = ss:tostring()
    -- if error, check if current_node.attr.value is nil
  elseif current_node.is_String then
    ss:addmany("```nelua\n", #current_node.attr.value, " bytes", "\n```")
    content = ss:tostring()
  elseif current_node.is_Pair then
    ss:addmany(current_node[1], "\n```nelua\n", "Type: ", current_node[2].attr.type)
    if current_node[2].attr.value then
      ss:add(" = ")
      if tostring(current_node[2].attr.type) == "string" then
        if current_node[2].attr.value:match("[\r\n]") then
          ss:addmany("[[", current_node[2].attr.value, "]]")
        else
          ss:addmany('"', current_node[2].attr.value, '"')
        end
      else
        ss:add(current_node[2].attr.value)
      end
    end
    ss:add("\n```")
    content = ss:tostring()
  elseif current_node.is_call then
    local type_name, node_type = tostring(current_node.attr.calleesym):match("^(.-):%s*(.+)")
    ss:addmany(type_name, "\n```nelua\n", "Type: ", node_type, "\n```")
    content = ss:tostring()
  elseif current_node.is_DotIndex then
    local sss = sstream()
    local parent_name = ""
    if current_node[2].attr.name then
      sss:addmany(current_node[2].attr.name, ".")
      parent_name = sss:tostring()
    elseif current_node[2].attr.dotfieldname then
      sss:addmany(current_node[2].attr.dotfieldname, ".")
      parent_name = sss:tostring()
    elseif not current_node[2].attr.name and not current_node[2].attr.dotfieldname and current_node[2].attr.type then
      sss:addmany(current_node[2].attr.type, ".")
      parent_name = sss:tostring()
    end
    ss:addmany(parent_name, current_node.attr.dotfieldname, "\n```nelua\n", "Type: ", current_node.attr.type, "\n```")
    content = ss:tostring()
  elseif not current_node.attr.name and current_node.attr.value then
    ss:addmany(current_node[1], "\n```nelua\n", "Type: ", current_node.attr.value, "\n```")
    content = ss:tostring()
  end

  local hover_response = response.hover(request_id, content)
  io.write(hover_response)
  io.flush()
end
