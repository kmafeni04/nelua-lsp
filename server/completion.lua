local response = require("utils.response")
local logger = require("utils.logger")
local analyze_ast = require("utils.analyze_ast")

local keywords = {}
keywords["local"] = true
keywords["global"] = true
keywords["function"] = true
keywords["nil"] = true
keywords["true"] = true
keywords["false"] = true
keywords["for"] = true
keywords["if"] = true
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
local function gen_builtin_completions(comp_list)
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
local function gen_snippets(comp_list)
  gen_completion("if .. then", comp_item_kind.Snippet, "", "if $1 then\n\t\nend", insert_text_format.Snippet, comp_list)

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
---@param comp_list CompItem[]
local function gen_symbol_completions(scope, comp_list)
  if scope.parent then
    gen_symbol_completions(scope.parent, comp_list)
  end
  local unique_symbols = {}
  for _, symbol in pairs(scope.symbols) do
    local node = symbol.node
    if node then
      if node.is_call then
        unique_symbols[symbol.attr.name] = symbol
      elseif not node.is_ColonIndex and not node.is_DotIndex then
        unique_symbols[symbol.name] = symbol
      end
    end
  end
  for name, symbol in pairs(unique_symbols) do
    -- for k, v in pairs(symbol) do
    --   logger.log(tostring(k) .. "  k")
    --   logger.log(tostring(v) .. "  v")
    -- end
    local kind = comp_item_kind.Text
    local node = symbol.node
    if node then
      if node.attr.ftype then
        logger.log(node)
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
---@param documents table<string, string>
---@param ast_cache table<string, table>
---@return table? ast
return function(request_id, request_params, current_uri, documents, ast_cache)
  ---@type CompItem[]
  local comp_list = {}
  gen_keywords(comp_list)
  gen_snippets(comp_list)
  gen_builtin_completions(comp_list)

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
    -- for k, v in pairs(ast.scope.parent) do
    --   logger.log(tostring(k) .. "  k")
    --   logger.log(tostring(v) .. "  v")
    -- end
    -- logger.log(ast.scope)
    gen_symbol_completions(ast.scope, comp_list)
    response.completion(request_id, comp_list)
    return ast
  else
    response.completion(request_id, comp_list)
    return nil
  end
end
