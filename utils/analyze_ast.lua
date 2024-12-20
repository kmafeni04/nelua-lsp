local except = require("nelua.utils.except")
local analyzer = require("nelua.analyzer")
local AnalyzerContext = require("nelua.analyzercontext")
local aster = require("nelua.aster")
local generator = require("nelua.cgenerator")

local logger = require("utils.logger")

---@param current_file_content string
---@param current_file_path string
---@return table? ast
---@return table? err
return function(current_file_content, current_file_path)
  local ast
  local ok, err = except.trycall(function()
    ast = aster.parse(current_file_content, current_file_path)
    local context = AnalyzerContext(analyzer.visitors, ast, generator)
    except.try(function()
      context = analyzer.analyze(context)
      -- collectgarbage()
    end, function(e)
      e.message = ("%s%s"):format(context:get_visiting_traceback(1), e:get_message())
    end)
  end)
  if ok then
    return ast, nil
  else
    if type(err) == "string" then
      local actual_err = err
      err = {}
      err.__index = err
      setmetatable(err.__index, err)
      err.message = actual_err
      err.__tostring = function()
        return err.message
      end
    end
    return ast, err
  end
end
