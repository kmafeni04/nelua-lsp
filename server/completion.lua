local switch = require("lib.switch")

local response = require("utils.response")
local logger = require("utils.logger")
local find_nodes = require("utils.find_nodes")
-- local analyze_ast = require("utils.analyze_ast")

local keywords = {}
keywords["local"] = true
keywords["global"] = true
keywords["function"] = true
keywords["nil"] = true
keywords["true"] = true
keywords["false"] = true
keywords["for"] = true
keywords["if"] = true
keywords["elseif"] = true
keywords["else"] = true
keywords["while"] = true
keywords["do"] = true
keywords["end"] = true
keywords["in"] = true
keywords["then"] = true
keywords["not"] = true
keywords["defer"] = true
keywords["break"] = true
keywords["fallthrough"] = true
keywords["switch"] = true

local symbols = {}

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
local function gen_builtin_funcs_completions(comp_list)
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
  -- gen_completion("Allocator", comp_item_kind.Class, "", "Allocator", insert_text_format.PlainText, comp_list)
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
local function gen_symbols(scope)
  if scope.parent then
    gen_symbols(scope.parent)
  end
  for _, symbol in pairs(scope.symbols) do
    local node = symbol.node
    if node then
      if node.is_call then
        symbols[symbol.attr.name] = symbol
      elseif not node.is_ColonIndex and not node.is_DotIndex then
        symbols[symbol.name] = symbol
      end
    end
  end
end

---@param scope table
local function gen_index_symbols(scope)
  if scope.parent then
    gen_index_symbols(scope.parent)
  end
  for _, symbol in pairs(scope.symbols) do
    local node = symbol.node
    if node then
      if node.is_ColonIndex or node.is_DotIndex then
        symbols[symbol.name] = symbol
        -- logger.log(symbols[symbol.name])
      end
    end
  end
end

---@param comp_list CompItem[]
local function gen_symbol_completions(comp_list)
  for name, symbol in pairs(symbols) do
    -- for k, v in pairs(symbol) do
    --   logger.log(tostring(k) .. "  k")
    --   logger.log(tostring(v) .. "  v")
    -- end
    local kind = comp_item_kind.Text
    local node = symbol.node
    if node then
      if node.attr.ftype then
        kind = comp_item_kind.Function
      elseif node.is_Id or node.is_IdDecl then
        kind = comp_item_kind.Variable
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
---@param current_uri string
---@param current_file string
---@param ast_cache table<string, table>
---@return table? ast
return function(request_id, request_params, current_uri, current_file, ast_cache)
  local current_line = request_params.position.line
  local current_char = request_params.position.character

  ---@type CompItem[]
  local comp_list = {}
  gen_keywords(comp_list)
  gen_snippets(comp_list)
  gen_builtin_funcs_completions(comp_list)
  gen_types(comp_list)
  -- TODO: NOT PERFORMANT
  -- local unique_words = {}
  -- for _, doc in pairs(documents) do
  --   for word in doc:gmatch("%f[%w_][%w_]+%f[^%w_]") do
  --     unique_words[word] = true
  --   end
  -- end
  -- for word in pairs(unique_words) do
  --   if not keywords[word] then
  --     gen_completion(word, comp_item_kind.Text, "", insert_text_format.PlainText, comp_list)
  --   end
  -- end
  local ast = ast_cache[current_uri]
  if ast then
    gen_symbols(ast.scope)
    -- logger.log(#symbols)
    -- for k, v in pairs(ast.scope.parent) do
    --   logger.log(tostring(k) .. "  k")
    --   logger.log(tostring(v) .. "  v")
    -- end
    -- logger.log(ast.scope)
    if request_params.context and request_params.context.triggerKind == 2 then
      local trig_char = request_params.context.triggerCharacter
      switch(trig_char, {
        [{ "@", "*" }] = function()
          comp_list = {}
          gen_types(comp_list)
          for name, symbol in pairs(symbols) do
            local node = symbol.node
            if node and node.attr.type.is_type then
              gen_completion(name, comp_item_kind.Class, "", name, insert_text_format.PlainText, comp_list)
            end
          end
        end,
        ["&"] = function()
          comp_list = {}
          for name, symbol in pairs(symbols) do
            local node = symbol.node
            if node and (node.is_Id or node.is_IdDecl) and not node.attr.ftype and not node.attr.type.is_type then
              gen_completion(name, comp_item_kind.Variable, "", name, insert_text_format.PlainText, comp_list)
            end
          end
        end,
        ["$"] = function()
          comp_list = {}
          for name, symbol in pairs(symbols) do
            local node = symbol.node
            if node and node.attr.type and node.attr.type.is_pointer then
              gen_completion(name, comp_item_kind.Variable, "", name, insert_text_format.PlainText, comp_list)
            end
          end
        end,
        ["."] = function()
          comp_list = {}
          local found_nodes, err = find_nodes(current_file, current_line, current_char - 1, ast)
          if found_nodes then
            local last_node = found_nodes[#found_nodes]
            gen_index_symbols(ast.scope)
            for name, symbol in pairs(symbols) do
              local node = symbol.node
              if node and node.is_DotIndex and last_node.is_Id then
                if last_node.attr.type.is_type and (name:match("^(.+)%..*$") == tostring(last_node.attr.name)) then
                  name = name:match("^.+%.(.*)$")
                  gen_completion(
                    name,
                    comp_item_kind.Field,
                    "```nelua\nType: " .. tostring(node.attr.type) .. "\n```",
                    name,
                    insert_text_format.PlainText,
                    comp_list
                  )
                elseif
                  name:match("^(.+)%..*$") == tostring(last_node.attr.type) and not last_node.attr.type.is_string
                then
                  name = name:match("^.+%.(.*)$")
                  gen_completion(
                    name,
                    comp_item_kind.Field,
                    "```nelua\nType: " .. tostring(node.attr.type) .. "\n```",
                    name,
                    insert_text_format.PlainText,
                    comp_list
                  )
                end
              end
            end
          else
            logger.log(err)
          end
        end,
        [":"] = function()
          comp_list = {}
          local found_nodes, err = find_nodes(current_file, current_line, current_char - 1, ast)
          if found_nodes then
            local last_node = found_nodes[#found_nodes]
            local previous_node = found_nodes[#found_nodes - 1]
            gen_index_symbols(ast.scope)
            if previous_node.is_VarDecl then
              comp_list = {}
              gen_types(comp_list)
              for name, symbol in pairs(symbols) do
                local node = symbol.node
                if node and node.attr.type.is_type then
                  gen_completion(name, comp_item_kind.Class, "", name, insert_text_format.PlainText, comp_list)
                end
              end
            else
              for name, symbol in pairs(symbols) do
                local node = symbol.node
                if node and node.attr.ftype and last_node.is_Id then
                  if name:match("^(.+)%..*$") == tostring(last_node.attr.type) then
                    name = name:match("^.+%.(.*)$")
                    gen_completion(
                      name,
                      comp_item_kind.Method,
                      "```nelua\nType: " .. tostring(node.attr.type) .. "\n```",
                      name,
                      insert_text_format.PlainText,
                      comp_list
                    )
                  end
                end
              end
            end
          else
            logger.log(err)
          end
        end,
      })
    else
      gen_symbol_completions(comp_list)
    end
  end
  response.completion(request_id, comp_list)
end
