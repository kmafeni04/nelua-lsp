-- TODO: If workspace folder is provided, use that instead of the git root path
-- TODO: Figure out what is causing the lsp to be so slow on larger files

local rpc = require("utils.rpc")
local switch = require("libs.switch")
local server = require("utils.server")
local methods = require("methods")
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
    logger.log("Method: " .. request.method .. " ID: " .. (request.id or "N/A"))
    switch(request.method, {
      ["initialize"] = function()
        methods.initialize(request.id)
      end,
      ["textDocument/didOpen"] = function()
        local root_path_not_found =
          root_path:match("fatal: not a git repository %(or any of the parent directories%): %.git")

        if root_path_not_found then
          root_path = current_uri:sub(#"file:///"):gsub("/[^/]+%.nelua", "")
        end

        current_file_content = request.params.textDocument.text
        documents[current_uri] = current_file_content

        local ast, diagnostics = methods.diagnostic(current_file_content, current_file_path, current_uri)
        server.send_notification("textDocument/publishDiagnostics", {
          uri = current_uri,
          diagnostics = diagnostics,
        })
        if ast then
          ast_cache[current_uri] = ast
        end
      end,
      ["textDocument/didChange"] = function()
        current_file_content = methods.did_change(current_file_content, request.params)
        documents[current_uri] = current_file_content

        local ast, diagnostics = methods.diagnostic(current_file_content, current_file_path, current_uri)
        server.send_notification("textDocument/publishDiagnostics", {
          uri = current_uri,
          diagnostics = diagnostics,
        })
        if ast then
          ast_cache[current_uri] = ast
        end
      end,
      ["textDocument/didSave"] = function()
        local current_file_prog <close> = io.open(current_file_path)
        if current_file_prog then
          current_file_content = current_file_prog:read("a")
          documents[current_uri] = current_file_content
        end
        local ast, diagnostics = methods.diagnostic(current_file_content, current_file_path, current_uri)
        server.send_notification("textDocument/publishDiagnostics", {
          uri = current_uri,
          diagnostics = diagnostics,
        })
        if ast then
          ast_cache[current_uri] = ast
        end
      end,
      ["textDocument/completion"] = function()
        local ast, items =
          methods.completion(request.params, documents, current_uri, current_file_path, current_file_content, ast_cache)
        if ast then
          ast_cache[current_uri] = ast
        end

        if next(items) then
          server.send_response(request.id, items)
        else
          server.send_error(request.id, server.LspErrorCode.RequestFailed, "Failed to provide any completions")
        end
      end,
      ["completionItem/resolve"] = function() end,
      ["textDocument/hover"] = function()
        current_file_content = documents[current_uri]
        local ast = ast_cache[current_uri]

        local hover_content = methods.hover(request.params, current_file_content, current_file_path, ast)
        if hover_content then
          local result = {
            contents = hover_content,
          }
          server.send_response(request.id, result)
        else
          server.send_error(request.id, server.LspErrorCode.RequestFailed, "Failed to provide any hover information")
        end
      end,
      ["textDocument/definition"] = function()
        local current_line = request.params.position.line
        local current_char = request.params.position.character
        current_file_content = documents[current_uri]
        local ast = ast_cache[current_uri]

        local locs = methods.definition(
          root_path,
          documents,
          current_file_content,
          current_file_path,
          current_line,
          current_char,
          ast
        )
        if locs then
          server.send_response(request.id, locs)
        else
          server.send_error(request.id, server.LspErrorCode.RequestFailed, "Failed to find definition")
        end
      end,
      ["textDocument/rename"] = function()
        local changes = methods.rename(request.params, current_file_content, ast_cache[current_uri])
        local result = {
          changes = changes,
        }
        server.send_response(request.id, result)
      end,
      ["textDocument/didClose"] = function()
        documents[current_uri] = nil
        ast_cache[current_uri] = nil
      end,
      ["shutdown"] = function()
        methods.shutdown()
      end,
      ["exit"] = function()
        os.exit()
      end,
    })
  else
    logger.log(err)
  end
end
