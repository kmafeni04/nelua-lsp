local interp = require("libs.interp")
local logger = {}

if arg[1] == "DEBUG" then
  --- Create a new log file
  function logger.init()
    local log_file = io.open("/tmp/lsp.log", "w")
    local date = os.date("%Y/%m/%d", os.time())
    local time = os.date("%X", os.time())
    local logged_file = debug.getinfo(2).source
    local line = debug.getinfo(2).currentline
    assert(log_file):write(interp("[nelua_lsp] {{date}} {{time}} {{logged_file}}:{{line}}: Started\n"))
    assert(log_file):close()
  end

  --- Log new items separated by `", "`
  ---@param ... any
  function logger.log(...)
    local log_file = io.open("/tmp/lsp.log", "a")
    local date = os.date("%Y/%m/%d", os.time())
    local time = os.date("%X", os.time())
    local logged_file = debug.getinfo(2).source
    local line = debug.getinfo(2).currentline
    local msgs = { ... }
    local msgs_no_nil = {}
    for i, v in ipairs(msgs) do
      msgs_no_nil[i] = tostring(v)
    end
    local msg = table.concat(msgs_no_nil, ", ")
    assert(log_file):write(interp("[nelua_lsp] {{date}} {{time}} {{logged_file}}:{{line}}: {{msg}}\n"))
    assert(log_file):close()
  end
else
  function logger.init() end
  function logger.log(...) end
end

return logger
