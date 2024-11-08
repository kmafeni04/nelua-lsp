local interp = require("lib.interp")
local json = require("utils.json")
local switch = require("lib.switch")
local server = require("server")
local logger = require("utils.logger")

logger.init()

---@type table<string, string>
local documents = {}
local current_file = ""
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
        local current_uri = request.params.textDocument.uri

        local root_path_not_found =
          root_path:match("fatal: not a git repository %(or any of the parent directories%): %.git")

        if root_path_not_found then
          root_path = current_uri:sub(#"file:///"):gsub("/[^/]+%.nelua", "")
        end

        local current_file_path = current_uri:sub(#"file://" + 1)

        assert(current_uri == "file://" .. current_file_path, "file paths do not match")
        current_file = server.did_open(current_file_path)
      end,
      ["textDocument/hover"] = function()
        local current_line = request.params.position.line
        local current_char = request.params.position.character
        server.hover(current_file, current_line, current_char)
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
