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
local parse_err = false
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
    logger.log("Method: " .. request.method)
    switch(request.method, {
      ["initialize"] = function()
        server.initialize(request.id)
      end,
      ["textDocument/didOpen"] = function()
        current_uri = request.params.textDocument.uri

        local root_path_not_found =
          root_path:match("fatal: not a git repository %(or any of the parent directories%): %.git")

        if root_path_not_found then
          root_path = current_uri:sub(#"file:///"):gsub("/[^/]+%.nelua", "")
        end

        current_file_path = current_uri:sub(#"file://" + 1)

        assert(current_uri == "file://" .. current_file_path, "current_uri does not match current file path")
        current_file = server.did_open(current_file_path)
        documents[current_uri] = current_file

        parse_err = server.diagnostic(documents, current_file, current_file_path, current_uri)
      end,
      ["textDocument/didChange"] = function()
        current_file = server.did_change(documents, request.params, current_uri)
        parse_err = server.diagnostic(documents, current_file, current_file_path, current_uri)
      end,
      ["textDocument/didSave"] = function()
        parse_err = server.diagnostic(documents, current_file, current_file_path, current_uri)
      end,
      ["textDocument/hover"] = function()
        local current_line = request.params.position.line
        local current_char = request.params.position.character

        server.hover(request.id, documents, current_uri, current_file, current_file_path, current_line, current_char)
      end,
      ["textDocument/didClose"] = function()
        assert(current_uri:match("file://"), "provided string is not a uri")
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
