local interp = require("lib.interp")
local json = require("lib.json")
local logger = require("utils.logger")

local content = ""

while true do
  local header = io.read("L")
  logger.log(header)
end
