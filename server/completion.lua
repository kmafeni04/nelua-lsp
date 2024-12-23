-- TODO: Check how methods for generics like `sequence` work as pressing `:` shows no methods
local switch = require("lib.switch")

local response = require("utils.response")
local logger = require("utils.logger")
local analyze_ast = require("utils.analyze_ast")
local find_nodes = require("utils.find_nodes")
local find_pos = require("utils.find_pos")
local pos_to_line_and_char = require("utils.pos_to_line_char")

local keywords = {
  ["local"] = true,
  ["global"] = true,
  ["function"] = true,
  ["nil"] = true,
  ["true"] = true,
  ["false"] = true,
  ["for"] = true,
  ["if"] = true,
  ["elseif"] = true,
  ["else"] = true,
  ["while"] = true,
  ["do"] = true,
  ["end"] = true,
  ["in"] = true,
  ["then"] = true,
  ["not"] = true,
  ["defer"] = true,
  ["or"] = true,
  ["break"] = true,
  ["goto"] = true,
  ["fallthrough"] = true,
  ["switch"] = true,
  ["repeat"] = true,
  ["until"] = true,
  ["return"] = true,
}

local SYMBOL_NAME_MATCH <const> = "^(.+)//.*$"

---@enum InsertTextFormat
local insert_text_format = {
  PlainText = 1,
  Snippet = 2,
}

---@enum CompItemKind
local comp_item_kind = {
  Text = 1,
  Method = 2,
  Function = 3,
  Constructor = 4,
  Field = 5,
  Variable = 6,
  Class = 7,
  Interface = 8,
  Module = 9,
  Property = 10,
  Unit = 11,
  Value = 12,
  Enum = 13,
  Keyword = 14,
  Snippet = 15,
  Color = 16,
  File = 17,
  Reference = 18,
  Folder = 19,
  EnumMember = 20,
  Constant = 21,
  Struct = 22,
  Event = 23,
  Operator = 24,
  TypeParameter = 25,
}

---@param label string
---@param kind CompItemKind
---@param doc string
---@param inser_text string
---@param fmt InsertTextFormat
---@param comp_list CompItem[]
local function gen_completion(label, kind, doc, inser_text, fmt, comp_list)
  ---@type CompItem
  local comp = {
    label = label,
    kind = kind,
    documentation = doc,
    insertText = inser_text,
    insertTextFormat = fmt,
  }
  table.insert(comp_list, comp)
end

---@param comp_list CompItem[]
local function gen_keywords(comp_list)
  for word in pairs(keywords) do
    gen_completion(word, comp_item_kind.Keyword, "", word, insert_text_format.PlainText, comp_list)
  end
end

---@param comp_list CompItem[]
local function gen_builtin_funcs(comp_list)
  gen_completion(
    "require",
    comp_item_kind.Function,
    "```nelua\nType: function(modname: string)\n```",
    "require",
    insert_text_format.PlainText,
    comp_list
  )
  gen_completion(
    "print",
    comp_item_kind.Function,
    "```nelua\nType: polyfunction(varargs): void\n```",
    "print",
    insert_text_format.PlainText,
    comp_list
  )
  gen_completion(
    "panic",
    comp_item_kind.Function,
    "```nelua\nType: function(message: string): void\n```",
    "panic",
    insert_text_format.PlainText,
    comp_list
  )
  gen_completion(
    "error",
    comp_item_kind.Function,
    "```nelua\nType: function(message: string): void\n```",
    "error",
    insert_text_format.PlainText,
    comp_list
  )
  gen_completion(
    "assert",
    comp_item_kind.Function,
    "```nelua\nType: polyfunction(v: auto, message: facultative(string)): void\n```",
    "assert",
    insert_text_format.PlainText,
    comp_list
  )
  gen_completion(
    "check",
    comp_item_kind.Function,
    "```nelua\nType: polyfunction(cond: boolean, message: facultative(string)): void\n```",
    "check",
    insert_text_format.PlainText,
    comp_list
  )
  gen_completion(
    "likely",
    comp_item_kind.Function,
    "```nelua\nType: function(cond: boolean): boolean\n```",
    "likely",
    insert_text_format.PlainText,
    comp_list
  )
  gen_completion(
    "unlikely",
    comp_item_kind.Function,
    "```nelua\nType: function(cond: boolean): boolean\n```",
    "unlikely",
    insert_text_format.PlainText,
    comp_list
  )
end

---@param comp_list CompItem[]
local function gen_primitive_types_completions(comp_list)
  gen_completion("auto", comp_item_kind.Class, "", "auto", insert_text_format.PlainText, comp_list)

  gen_completion("boolean", comp_item_kind.Class, "", "boolean", insert_text_format.PlainText, comp_list)

  gen_completion("number", comp_item_kind.Class, "", "number", insert_text_format.PlainText, comp_list)

  gen_completion("integer", comp_item_kind.Class, "", "integer", insert_text_format.PlainText, comp_list)

  gen_completion("uinteger", comp_item_kind.Class, "", "uinteger", insert_text_format.PlainText, comp_list)

  gen_completion("byte", comp_item_kind.Class, "", "byte", insert_text_format.PlainText, comp_list)

  gen_completion("isize", comp_item_kind.Class, "", "isize", insert_text_format.PlainText, comp_list)

  gen_completion("int8", comp_item_kind.Class, "", "int8", insert_text_format.PlainText, comp_list)

  gen_completion("int16", comp_item_kind.Class, "", "int16", insert_text_format.PlainText, comp_list)

  gen_completion("int32", comp_item_kind.Class, "", "int32", insert_text_format.PlainText, comp_list)

  gen_completion("int64", comp_item_kind.Class, "", "int64", insert_text_format.PlainText, comp_list)

  gen_completion(
    "int128",
    comp_item_kind.Class,
    "Only supported by some C compilers and architectures",
    "int128",
    insert_text_format.PlainText,
    comp_list
  )

  gen_completion("usize", comp_item_kind.Class, "", "usize", insert_text_format.PlainText, comp_list)

  gen_completion("uint8", comp_item_kind.Class, "", "uint8", insert_text_format.PlainText, comp_list)

  gen_completion("uint16", comp_item_kind.Class, "", "uint16", insert_text_format.PlainText, comp_list)

  gen_completion("uint32", comp_item_kind.Class, "", "uint32", insert_text_format.PlainText, comp_list)

  gen_completion("uint64", comp_item_kind.Class, "", "uint64", insert_text_format.PlainText, comp_list)

  gen_completion(
    "uint128",
    comp_item_kind.Class,
    "Only supported by some C compilers and architectures",
    "uint128",
    insert_text_format.PlainText,
    comp_list
  )

  gen_completion("float32", comp_item_kind.Class, "", "float32", insert_text_format.PlainText, comp_list)

  gen_completion("float64", comp_item_kind.Class, "", "float64", insert_text_format.PlainText, comp_list)

  gen_completion(
    "float128",
    comp_item_kind.Class,
    "Only supported by some C compilers and architectures",
    "float128",
    insert_text_format.PlainText,
    comp_list
  )

  gen_completion("integer", comp_item_kind.Class, "", "integer", insert_text_format.PlainText, comp_list)

  gen_completion("string", comp_item_kind.Class, "", "string", insert_text_format.PlainText, comp_list)

  gen_completion("Array", comp_item_kind.Snippet, "", "[${1:N}]${2:T}", insert_text_format.Snippet, comp_list)

  gen_completion("enum", comp_item_kind.Class, "", "enum", insert_text_format.PlainText, comp_list)
  gen_completion("enum", comp_item_kind.Snippet, "", "enum{$1}", insert_text_format.Snippet, comp_list)

  gen_completion("record", comp_item_kind.Class, "", "record", insert_text_format.PlainText, comp_list)
  gen_completion("record", comp_item_kind.Snippet, "", "record{$1}", insert_text_format.Snippet, comp_list)

  gen_completion("union", comp_item_kind.Class, "", "union", insert_text_format.PlainText, comp_list)
  gen_completion("union", comp_item_kind.Snippet, "", "union{$1}", insert_text_format.Snippet, comp_list)

  gen_completion("pointer", comp_item_kind.Class, "", "pointer", insert_text_format.PlainText, comp_list)

  gen_completion("nilptr", comp_item_kind.Class, "", "nilptr", insert_text_format.PlainText, comp_list)

  gen_completion("function", comp_item_kind.Class, "", "function($1)", insert_text_format.Snippet, comp_list)

  gen_completion("niltype", comp_item_kind.Class, "", "niltype", insert_text_format.PlainText, comp_list)

  gen_completion("void", comp_item_kind.Class, "", "void", insert_text_format.PlainText, comp_list)

  gen_completion("type", comp_item_kind.Class, "", "type", insert_text_format.PlainText, comp_list)

  gen_completion("facultative", comp_item_kind.Class, "", "facultative(${1:T})", insert_text_format.Snippet, comp_list)

  gen_completion(
    "overload",
    comp_item_kind.Class,
    "",
    "overload(${1:T1}, ${2:T2})",
    insert_text_format.Snippet,
    comp_list
  )
end

---@param comp_list CompItem[]
local function gen_lib_types_completions(comp_list)
  gen_completion("io", comp_item_kind.Class, "", "io", insert_text_format.PlainText, comp_list)

  gen_completion("filestream", comp_item_kind.Class, "", "filestream", insert_text_format.PlainText, comp_list)

  gen_completion("math", comp_item_kind.Class, "", "math", insert_text_format.PlainText, comp_list)

  gen_completion("memory", comp_item_kind.Class, "", "memory", insert_text_format.PlainText, comp_list)

  gen_completion("os", comp_item_kind.Class, "", "os", insert_text_format.PlainText, comp_list)

  gen_completion("traits", comp_item_kind.Class, "", "traits", insert_text_format.PlainText, comp_list)

  gen_completion("utf8", comp_item_kind.Class, "", "utf8", insert_text_format.PlainText, comp_list)

  gen_completion("coroutine", comp_item_kind.Class, "", "coroutine", insert_text_format.PlainText, comp_list)

  gen_completion("hash", comp_item_kind.Class, "", "hash", insert_text_format.PlainText, comp_list)

  gen_completion("Allocator", comp_item_kind.Class, "", "Allocator", insert_text_format.PlainText, comp_list)
end

---@param comp_list CompItem[]
local function gen_generic_types_completions(comp_list)
  gen_completion("span", comp_item_kind.Snippet, "", "span(${1:T})", insert_text_format.Snippet, comp_list)

  gen_completion("stringbuilder", comp_item_kind.Snippet, "", "stringbuilder", insert_text_format.PlainText, comp_list)

  gen_completion("vector", comp_item_kind.Snippet, "", "vector(${1:T})", insert_text_format.Snippet, comp_list)

  gen_completion("sequence", comp_item_kind.Snippet, "", "sequence(${1:T})", insert_text_format.Snippet, comp_list)

  gen_completion("list", comp_item_kind.Snippet, "", "list(${1:T})", insert_text_format.Snippet, comp_list)

  gen_completion("hashmap", comp_item_kind.Snippet, "", "hashmap(${1:K},${2:V})", insert_text_format.Snippet, comp_list)

  gen_completion(
    "ArenaAllocator",
    comp_item_kind.Snippet,
    "",
    "ArenaAllocator(${1:SIZE},${2:ALIGN})",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "StackAllocator",
    comp_item_kind.Snippet,
    "",
    "StackAllocator(${1:SIZE},${2:ALIGN})",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "PoolAllocator",
    comp_item_kind.Snippet,
    "",
    "PoolAllocator(${1:T},${2:SIZE})",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "HeapAllocator",
    comp_item_kind.Snippet,
    "",
    "HeapAllocator(${1:SIZE})",
    insert_text_format.Snippet,
    comp_list
  )
end

local function gen_types(comp_list)
  gen_primitive_types_completions(comp_list)
  gen_lib_types_completions(comp_list)
  gen_generic_types_completions(comp_list)
end

---@param comp_list CompItem[]
local function gen_snippets(comp_list)
  gen_completion("if .. then", comp_item_kind.Snippet, "", "if $1 then\n\t\nend", insert_text_format.Snippet, comp_list)

  gen_completion("else .. end", comp_item_kind.Snippet, "", "else\n\t$1\nend", insert_text_format.Snippet, comp_list)

  gen_completion("elseif .. then", comp_item_kind.Snippet, "", "elseif $1 then", insert_text_format.Snippet, comp_list)

  gen_completion(
    "while .. do",
    comp_item_kind.Snippet,
    "",
    "while $1 do\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion("do .. end", comp_item_kind.Snippet, "", "do\n\t$1\nend", insert_text_format.Snippet, comp_list)

  gen_completion(
    "switch .. end",
    comp_item_kind.Snippet,
    "",
    "switch $1 do\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion("case .. then", comp_item_kind.Snippet, "", "case $1 then", insert_text_format.Snippet, comp_list)

  gen_completion("defer .. end", comp_item_kind.Snippet, "", "defer\n\t$1\nend", insert_text_format.Snippet, comp_list)

  gen_completion(
    "repeat .. until",
    comp_item_kind.Snippet,
    "",
    "repeat\n\t\nuntil $1",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "for .. func",
    comp_item_kind.Snippet,
    "",
    "for ${1:value} in ${2:func()} do\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "for .. pairs",
    comp_item_kind.Snippet,
    "",
    "for ${1:key}, ${2:value} in pairs(${3:a}) do\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "for .. pairs",
    comp_item_kind.Snippet,
    "",
    "for ${1:key}, ${2:value} in pairs(${3:a}) do\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "for .. mpairs",
    comp_item_kind.Snippet,
    "",
    "for ${1:key}, ${2:value} in mpairs(${3:a}) do\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "for .. ipairs",
    comp_item_kind.Snippet,
    "",
    "for ${1:index}, ${2:value} in ipairs(${3:a}) do\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "for .. mipairs",
    comp_item_kind.Snippet,
    "",
    "for ${1:index}, ${2:value} in mipairs(${3:a}) do\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "for i = ..",
    comp_item_kind.Snippet,
    "",
    "for ${1:i} = ${2:1}, ${3:10} do\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "local function",
    comp_item_kind.Snippet,
    "",
    "local function $1()\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "global function",
    comp_item_kind.Snippet,
    "",
    "global function $1()\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )

  gen_completion(
    "function",
    comp_item_kind.Snippet,
    "",
    "function $1()\n\t\nend",
    insert_text_format.Snippet,
    comp_list
  )
end

---@param scope table
---@param pos integer
---@param current_file_path string
---@param symbols table
local function gen_symbols(scope, pos, current_file_path, symbols)
  if type(scope) == "table" then
    if scope.parent then
      gen_symbols(scope.parent, pos, current_file_path, symbols)
    end
    for _, symbol in ipairs(scope.symbols) do
      if symbol.name == "self" and symbol.usedby then
        local parent, _ = next(symbol.usedby)
        local parent_node = parent.node
        symbol.node = {
          src = parent_node.src,
          pos = parent_node.pos,
          _astnode = true,
          -- endpos = parent_node.endpos,
          attr = {
            name = symbol.name,
            type = symbol.type,
          },
        }
      end
      local node = symbol.node
      if
        node and ((node._astnode and node.pos and pos >= node.pos) or (node.src and node.src.name ~= current_file_path))
      then
        if
          node.attr
          and node.attr.name
          and not node.attr.name:match("^[%w_]+%(")
          and not node.attr.name:match("^[%w_]+T%.") -- Generics
        then
          if node.attr.ftype then
            if node.attr.metafunc then
              if node[2].attr.global or node[2].src.name == current_file_path then
                symbols[symbol.name .. "//" .. tostring(node.attr.type)] = symbol
              end
            else
              -- Concatenated with type to avoid clashes of the same name
              symbols[symbol.name .. "//" .. tostring(node.attr.type)] = symbol
            end
          else
            symbols[node.attr.name .. "//" .. tostring(node.attr.type)] = symbol
          end
        end
      end
    end
  end
end

---@param comp_list CompItem[]
---@param symbols table
local function gen_symbol_completions(comp_list, symbols)
  for key, symbol in pairs(symbols) do
    local name = key:match(SYMBOL_NAME_MATCH)
    local kind = comp_item_kind.Variable
    local node = symbol.node
    if node then
      if node.attr.ftype then
        kind = comp_item_kind.Function
      elseif node.attr.type and node.attr.type.is_type then
        kind = comp_item_kind.Class
      end
    end
    gen_completion(
      tostring(name),
      kind,
      "```nelua\nType: " .. tostring(symbol.type) .. "\n```",
      tostring(name),
      insert_text_format.PlainText,
      comp_list
    )
  end
end

---@param request_id integer
---@param request_params table
---@param documents table<string, string>
---@param current_uri string
---@param current_file_path string
---@param current_file_content string
---@param ast_cache table<string, table>
---@return table? ast
return function(request_id, request_params, documents, current_uri, current_file_path, current_file_content, ast_cache)
  local current_line = request_params.position.line
  local current_char = request_params.position.character

  local symbols = {}
  ---@type CompItem[]
  local comp_items = {}

  gen_keywords(comp_items)
  gen_snippets(comp_items)
  gen_builtin_funcs(comp_items)
  gen_types(comp_items)
  local content = current_file_content
  local _pos = find_pos(current_file_content, current_line, current_char)
  -- some hack for get ast node
  local before = content:sub(1, _pos - 1):gsub("%a%w*$", "")
  local after = content:sub(_pos):gsub("^[%.:]?%a%w*", "")
  local kind = "normal"
  if before:match("%.$") then
    before = before:sub(1, -2) .. "()"
    kind = "field"
  elseif before:match(":$") then
    before = before:sub(1, -2) .. "()"
    kind = "colon"
  end
  content = before .. after

  local ast, err = analyze_ast(content, current_file_path)

  local pos = #before
  local line, char = pos_to_line_and_char(_pos, content)
  if ast then
    ast_cache[current_uri] = ast
  else
    pos = _pos
    content = current_file_content
    line = current_line
    char = current_char
    ast = ast_cache[current_uri]
  end
  if ast then
    local found_nodes, find_err = find_nodes(content, line, char, ast)
    if found_nodes then
      local last_node = found_nodes[#found_nodes]
      -- Symbol generation
      for _, node in pairs(found_nodes) do
        if node.scope then
          gen_symbols(node.scope, pos, current_file_path, symbols)
        elseif node.is_Do then
          -- for loop variables
          local loop_nodes = node[1][2][2][1][2]
          for _, loop_node in pairs(loop_nodes) do
            if
              loop_node.attr
              and loop_node.attr.name
              and not loop_node.attr.name:match("^__.*")
              and not symbols[loop_node.attr.name .. "//" .. tostring(loop_node.attr.type)]
            then
              symbols[loop_node.attr.name .. "//" .. tostring(loop_node.attr.type)] = {
                node = loop_node,
                name = loop_node.attr.name,
                type = loop_node.attr.type,
              }
            end
          end
        elseif node.attr and node.attr.name and not symbols[node.attr.name .. "//" .. tostring(node.attr.type)] then
          symbols[node.attr.name .. "//" .. tostring(node.attr.type)] = {
            node = node,
            name = node.attr.name,
            type = node.attr.type,
          }
        end
      end
      gen_symbols(ast.scope, pos, current_file_path, symbols)
      gen_symbol_completions(comp_items, symbols)
      if request_params.context and request_params.context.triggerKind == 2 then
        local trig_char = request_params.context.triggerCharacter
        comp_items = {}
        switch(trig_char, {
          [{ "@", "*" }] = function()
            gen_types(comp_items)
            for key, symbol in pairs(symbols) do
              local name = key:match(SYMBOL_NAME_MATCH)
              local node = symbol.node
              if node and node.attr.type.is_type then
                gen_completion(name, comp_item_kind.Class, "", name, insert_text_format.PlainText, comp_items)
              end
            end
          end,
          ["&"] = function()
            for key, symbol in pairs(symbols) do
              local name = key:match(SYMBOL_NAME_MATCH)
              local node = symbol.node
              if node and (node.is_Id or node.is_IdDecl) and not node.attr.ftype and not node.attr.type.is_type then
                gen_completion(
                  name,
                  comp_item_kind.Variable,
                  node.attr.name .. "\n```nelua\nType: " .. tostring(node.attr.type) .. "\n```",
                  name,
                  insert_text_format.PlainText,
                  comp_items
                )
              end
            end
          end,
          ["$"] = function()
            for key, symbol in pairs(symbols) do
              local name = key:match(SYMBOL_NAME_MATCH)
              local node = symbol.node
              if node and node.attr.type and node.attr.type.is_pointer then
                gen_completion(
                  name,
                  comp_item_kind.Variable,
                  node.attr.name .. "\n```nelua\nType: " .. tostring(node.attr.type) .. "\n```",
                  name,
                  insert_text_format.PlainText,
                  comp_items
                )
              end
            end
          end,
          ["."] = function()
            if kind == "field" and last_node.is_call then
              if last_node.attr and last_node.attr.type and last_node.attr.type.fields then
                local node_type = last_node.attr.type
                if node_type.is_enum then
                  for field_name, field in pairs(node_type.fields) do
                    if type(field_name) == "string" and type(field) == "table" then
                      gen_completion(
                        field_name,
                        comp_item_kind.EnumMember,
                        field_name
                          .. "\n```nelua\nType: "
                          .. tostring(last_node.attr.type.subtype)
                          .. " = "
                          .. tostring(field.value),
                        field_name,
                        insert_text_format.PlainText,
                        comp_items
                      )
                    end
                  end
                elseif last_node.attr.type.is_record or last_node.attr.type.is_union then
                  for field_name, field in pairs(node_type.metafields) do
                    local comp_kind = comp_item_kind.Field
                    if field.metafunc then
                      comp_kind = comp_item_kind.Function
                    end
                    gen_completion(
                      field_name,
                      comp_kind,
                      field_name .. "\n```nelua\nType: " .. tostring(field.type),
                      field_name,
                      insert_text_format.PlainText,
                      comp_items
                    )
                  end
                end
              elseif
                last_node[2]
                and type(last_node[2]) == "table"
                and last_node[2].attr
                and last_node[2].attr.type
              then
                local node_type = last_node[2].attr.type
                if node_type.fields and not node_type.is_enum then
                  for field_name, field in pairs(node_type.fields) do
                    if type(field_name) == "string" and type(field) == "table" then
                      gen_completion(
                        field_name,
                        comp_item_kind.Field,
                        field_name .. "\n```nelua\nType: " .. tostring(field.type),
                        field_name,
                        insert_text_format.PlainText,
                        comp_items
                      )
                    end
                  end
                elseif node_type.name == "pointer" and node_type.subtype then
                  local subtype_node = node_type.subtype
                  if subtype_node and type(subtype_node) == "table" then
                    for field_name, field in pairs(subtype_node.fields) do
                      if type(field_name) == "string" and type(field) == "table" then
                        if not subtype_node.is_enum then
                          gen_completion(
                            field_name,
                            comp_item_kind.Field,
                            field_name .. "\n```nelua\nType: " .. tostring(field.type),
                            field_name,
                            insert_text_format.PlainText,
                            comp_items
                          )
                        end
                      end
                    end
                  end
                end
              end
            end
          end,
          [":"] = function()
            if kind == "colon" then
              if last_node.is_call then
                local node_type = last_node[2].attr.type
                for field_name, field in pairs(node_type.metafields) do
                  gen_completion(
                    field_name,
                    comp_item_kind.Function,
                    field_name .. "\n```nelua\nType: " .. tostring(field.type),
                    field_name,
                    insert_text_format.PlainText,
                    comp_items
                  )
                end
              elseif
                last_node.is_IdDecl
                or last_node.is_FuncDef
                or last_node.is_RecordType
                or last_node.is_UnionType
              then
                gen_types(comp_items)
                for key, symbol in pairs(symbols) do
                  local name = key:match(SYMBOL_NAME_MATCH)
                  local node = symbol.node
                  if node and node.attr and node.attr.type and node.attr.type.is_type then
                    gen_completion(name, comp_item_kind.Class, "", name, insert_text_format.PlainText, comp_items)
                  end
                end
              end
            end
          end,
        })
      end
    else
      logger.log(find_err)
    end
  end

  ---@param items CompItem[]
  ---@param prefix string
  ---@return CompItem[]
  local function get_prefixed_completions(items, prefix)
    table.sort(items, function(a, b)
      local a_has_prefix = a.label:sub(1, #prefix) == prefix
      local b_has_prefix = b.label:sub(1, #prefix) == prefix
      if a_has_prefix and b_has_prefix then
        return a.label < b.label
      end

      return a_has_prefix
    end)

    local prefixed_items = {}

    for i, item in ipairs(items) do
      if i > 10 then
        break
      end
      if item.label:sub(1, #prefix) == prefix then
        table.insert(prefixed_items, item)
      end
    end

    return prefixed_items
  end

  local current_prefix = ""
  local prefix_pos = find_pos(current_file_content, current_line, current_char) - 1
  while true do
    local c = current_file_content:sub(prefix_pos, prefix_pos)
    if not c:match("[%w_]") then
      break
    end
    prefix_pos = prefix_pos - 1
    current_prefix = c .. current_prefix
  end

  ---@type CompItem[]
  local items = get_prefixed_completions(comp_items, current_prefix)

  if not next(items) then
    local text_items = {}
    local mark = {}
    for _, doc in pairs(documents) do
      for word in doc:gmatch("[%w_]+") do
        if not mark[word] then
          mark[word] = true
          gen_completion(word, comp_item_kind.Text, "", word, insert_text_format.PlainText, text_items)
        end
      end
    end
    items = get_prefixed_completions(text_items, current_prefix)
  end

  response.completion(request_id, items)
end
