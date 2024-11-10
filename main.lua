local interp = require("lib.interp")
local json = require("utils.json")
local switch = require("lib.switch")
local server = require("server")
local logger = require("utils.logger")

logger.init()

---@type table<string, string>
local documents = {}
local current_uri = ""
local current_file = ""
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
  local request = json.decode(content)

  if request then
    if request.params.textDocument then
      current_uri = request.params.textDocument.uri
      current_file_path = current_uri:sub(#"file://" + 1)
    end
    logger.log("Method: " .. request.method)
    switch(request.method, {
      ["initialize"] = function()
        server.initialize(request.id)
      end,
      ["textDocument/didOpen"] = function()
        local root_path_not_found =
          root_path:match("fatal: not a git repository %(or any of the parent directories%): %.git")

        if root_path_not_found then
          root_path = current_uri:sub(#"file:///"):gsub("/[^/]+%.nelua", "")
        end

        current_file = server.did_open(current_file_path)
        documents[current_uri] = current_file

        server.diagnostic(documents, current_file, current_file_path, current_uri)
      end,
      ["textDocument/didChange"] = function()
        current_file = server.did_change(documents, request.params, current_uri)
        documents[current_uri] = current_file

        server.diagnostic(documents, current_file, current_file_path, current_uri)
      end,
      ["textDocument/didSave"] = function()
        server.diagnostic(documents, current_file, current_file_path, current_uri)
      end,
      ["textDocument/hover"] = function()
        local current_line = request.params.position.line
        local current_char = request.params.position.character
        current_file = documents[current_uri]

        server.hover(request.id, current_file, current_file_path, current_line, current_char)
      end,
      ["textDocument/definition"] = function()
        local current_line = request.params.position.line
        local current_char = request.params.position.character
        current_file = documents[current_uri]

        server.definition(request.id, documents, current_file, current_file_path, current_line, current_char)
      end,
      ["textDocument/didClose"] = function()
        documents[current_uri] = nil
      end,
      ["shutdown"] = function()
        server.shutdown()
      end,
      ["exit"] = function()
        os.exit()
      end,
    })
  end
end
