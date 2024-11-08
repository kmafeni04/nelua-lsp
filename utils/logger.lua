local interp = require("lib.interp")
local logger = {}

if arg[1] == "DEBUG" then
  function logger.init()
    local log_file = io.open("lsp.log", "w")
    local date = os.date("%Y/%m/%d", os.time())
    local time = os.date("%X", os.time())
    local logged_file = debug.getinfo(2).source
    local line = debug.getinfo(2).currentline
    assert(log_file):write(interp("[nelua_lsp] {{date}} {{time}} {{logged_file}}:{{line}}: Started\n"))
    assert(log_file):close()
  end

  function logger.log(msg)
    local log_file = io.open("lsp.log", "a")
    local date = os.date("%Y/%m/%d", os.time())
    local time = os.date("%X", os.time())
    local logged_file = debug.getinfo(2).source
    local line = debug.getinfo(2).currentline
    assert(log_file):write(interp("[nelua_lsp] {{date}} {{time}} {{logged_file}}:{{line}}: {{msg}}\n"))
    assert(log_file):close()
  end
else
  function logger.init() end
  function logger.log(msg) end
end

return logger
