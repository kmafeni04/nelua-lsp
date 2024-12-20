local sstream = require("nelua.utils.sstream")

local switch = require("lib.switch")
local get_comments = require("lib.nldoc").get_comments

local find_nodes = require("utils.find_nodes")
local logger = require("utils.logger")
local pos_to_line_and_char = require("utils.pos_to_line_char")
local response = require("utils.response")

---@param request_id integer
---@param current_file_content string
---@param current_file_path string
---@param current_line integer
---@param current_char integer
---@param ast table?
return function(request_id, current_file_content, current_file_path, current_line, current_char, ast)
  local ss = sstream()

  ---@param file string
  ---@param file_path string
  ---@param pos integer
  local function add_doc(file, file_path, pos)
    local line = pos_to_line_and_char(pos, file)
    local comments = get_comments(file, file_path)
    for _, comment in pairs(comments) do
      if type(comment) == "table" then
        if line == comment.endlineno then
          ss:addmany("\n\n`---`\n\n", comment.text, "\n")
          break
        end
      end
    end
  end

  local content = ""
  if ast then
    local found_nodes, err = find_nodes(current_file_content, current_line, current_char, ast)

    if found_nodes then
      local current_node = found_nodes[#found_nodes]

      if current_node.attr.builtin then
        ss:addmany(current_node.attr.name, "\n```nelua\nType: ")
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
        if current_node.attr.value and not current_node.attr.ftype then
          ss:add(" = ")
          if current_node.attr.type.is_string then
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
        if current_node.is_IdDecl then
          add_doc(current_file_content, current_file_path, current_node.pos)
        elseif current_node.attr.node then
          add_doc(current_node.attr.node.src.content, current_node.attr.node.src.name, current_node.attr.node.pos)
        end
        content = ss:tostring()
      elseif current_node.is_String then
        -- NOTE: if error occurs in future, check if current_node.attr.value is nil
        ss:addmany("```nelua\n", #current_node.attr.value, " bytes", "\n```")
        content = ss:tostring()
      elseif current_node.is_Pair then
        ss:addmany(current_node[1], "\n```nelua\n", "Type: ", current_node[2].attr.type)
        if current_node[2].attr.value then
          ss:add(" = ")
          if current_node[2].attr.type.is_string then
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
        add_doc(
          current_node.attr.calleesym.node.src.content,
          current_node.attr.calleesym.node.src.name,
          current_node.attr.calleesym.node.pos
        )
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
        elseif
          not current_node[2].attr.name
          and not current_node[2].attr.dotfieldname
          and current_node[2].attr.type
        then
          sss:addmany(current_node[2].attr.type, ".")
          parent_name = sss:tostring()
        end
        local name = ""
        if current_node.attr.dotfieldname then
          name = current_node.attr.dotfieldname
        else
          name = current_node[1]
        end
        ss:addmany(parent_name, name, "\n```nelua\n", "Type: ", current_node.attr.type, "\n```")
        if current_node.attr.node then
          add_doc(current_node.attr.node.src.content, current_node.attr.node.src.name, current_node.attr.node.pos)
        end
        content = ss:tostring()
      elseif current_node.is_FuncDef then
        ss:addmany(current_node.attr.name, "\n```nelua\nType: ", tostring(current_node.attr.type), "\n```\n")
        add_doc(current_file_content, current_file_path, current_node.pos)
        content = ss:tostring()
      elseif current_node.is_ColonIndex then
        ss:addmany(current_node.attr.name, "\n```nelua\n", "Type: ", current_node.attr.type, "\n```")
        add_doc(current_node.attr.node.src.content, current_node.attr.node.src.name, current_node.attr.node.pos)
        content = ss:tostring()
      elseif current_node.is_PointerType then
        --TODO: Display more information
        ss:addmany(current_node.attr.value, "\n```nelua\n", "Type: ", current_node.attr.type, "\n```")
        content = ss:tostring()
      elseif current_node.is_RecordType then
        --TODO: Display more information
        ss:addmany("record\n```nelua\n", "Type: ", current_node.attr.value, "\n```")
        content = ss:tostring()
      elseif not current_node.attr.name and current_node.attr.value then
        ss:addmany(current_node[1], "\n```nelua\n", "Type: ", current_node.attr.value, "\n```")
        content = ss:tostring()
      end
    else
      logger.log(err)
    end
  end

  response.hover(request_id, content)
end
