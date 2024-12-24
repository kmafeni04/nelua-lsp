-- TODO: If workspace folder is provided, use that instead of the git root path
-- TODO: Figure out what's is causing the lsp to be so slow

local rpc = require("utils.rpc")
local switch = require("lib.switch")
local server = require("utils.server")
local method = require("method")
local logger = require("utils.logger")

logger.init()

---@type table<string, string>
local documents = {}
---@type table<string, table>
local ast_cache = {}
local current_uri = ""
local current_file_content = ""
local current_file_path = ""
---@type string
local root_path = io.popen("git rev-parse --show-toplevel 2>&1"):read("l")

while true do
  ---@type string
  local header = io.read("L")
  local content_length = tonumber(header:match("(%d+)\r\n"))
  _ = io.read("L")
  ---@type string
  local content = io.read(content_length)
  local request, err = rpc.decode(content)

  if request then
    if request.params and request.params.textDocument then
      current_uri = request.params.textDocument.uri
      current_file_path = current_uri:sub(#"file://" + 1)
    end
    logger.log("Method: " .. request.method)
    switch(request.method, {
      ["initialize"] = function()
        method.initialize(request.id)
      end,
      ["textDocument/didOpen"] = function()
        local root_path_not_found =
          root_path:match("fatal: not a git repository %(or any of the parent directories%): %.git")

        if root_path_not_found then
          root_path = current_uri:sub(#"file:///"):gsub("/[^/]+%.nelua", "")
        end

        current_file_content = request.params.textDocument.text
        documents[current_uri] = current_file_content

        local ast = method.diagnostic(current_file_content, current_file_path, current_uri)
        if ast then
          ast_cache[current_uri] = ast
        end
      end,
      ["textDocument/didChange"] = function()
        current_file_content = method.did_change(current_file_content, request.params)
        documents[current_uri] = current_file_content

        local ast = method.diagnostic(current_file_content, current_file_path, current_uri)
        if ast then
          ast_cache[current_uri] = ast
        end
      end,
      ["textDocument/didSave"] = function()
        local current_file_prog <close> = io.open(current_file_path)
        if current_file_prog then
          current_file_content = current_file_prog:read("a")
        end
        local ast = method.diagnostic(current_file_content, current_file_path, current_uri)
        if ast then
          ast_cache[current_uri] = ast
        end
      end,
      ["textDocument/completion"] = function()
        local ast = method.completion(
          request.id,
          request.params,
          documents,
          current_uri,
          current_file_path,
          current_file_content,
          ast_cache
        )
        if ast then
          ast_cache[current_uri] = ast
        end
      end,
      ["completionItem/resolve"] = function() end,
      ["textDocument/hover"] = function()
        local current_line = request.params.position.line
        local current_char = request.params.position.character
        current_file_content = documents[current_uri]
        local ast = ast_cache[current_uri]

        method.hover(request.id, current_file_content, current_file_path, current_line, current_char, ast)
      end,
      ["textDocument/definition"] = function()
        local current_line = request.params.position.line
        local current_char = request.params.position.character
        current_file_content = documents[current_uri]
        local ast = ast_cache[current_uri]

        method.definition(
          request.id,
          root_path,
          documents,
          current_file_content,
          current_file_path,
          current_line,
          current_char,
          ast
        )
      end,
      ["textDocument/rename"] = function()
        method.rename(request.id, request.params, current_file_content, ast_cache[current_uri])
      end,
      ["textDocument/didClose"] = function()
        documents[current_uri] = nil
        ast_cache[current_uri] = nil
      end,
      ["shutdown"] = function()
        method.shutdown()
      end,
      ["exit"] = function()
        os.exit()
      end,
    })
  else
    logger.log(err)
  end
end
