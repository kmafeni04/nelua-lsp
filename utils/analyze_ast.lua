local except = require("nelua.utils.except")
local analyzer = require("nelua.analyzer")
local typedefs = require("nelua.typedefs")
local AnalyzerContext = require("nelua.analyzercontext")
local aster = require("nelua.aster")
local generator = require("nelua.cgenerator")

---@param current_file string
---@param current_file_path string
---@return table? ast
---@return table err
return function(current_file, current_file_path)
  local ast
  local ok, err = except.trycall(function()
    ast = aster.parse(current_file, current_file_path)
    local context = AnalyzerContext(analyzer.visitors, ast, generator)
    except.try(function()
      for _, v in pairs(typedefs.primtypes) do
        if v.metafields then
          v.metafields = {}
        end
      end

      context = analyzer.analyze(context)
    end, function(e)
      e.message = context:get_visiting_traceback(1) .. e:get_message()
    end)
    -- for k, v in pairs(context.context.context) do
    --   logger.log(tostring(k) .. "  k")
    --   logger.log(tostring(v) .. "  v")
    -- end
  end)
  if not ok then
    ast = nil
  end
  return ast, err
end
