local analyze_ast = require("utils.analyze_ast")
local logger = require("utils.logger")
local notification = require("utils.notification")

---@enum Severity
local Severity = {
  Error = 1,
  Warning = 2,
  Information = 3,
  Hint = 4,
}

---@param analysis string
---@param analysis_match string
---@param severity integer
---@return Diagnsotic
local function create_diagnostic(analysis, analysis_match, severity)
  ---@class Diagnsotic
  ---@field severity integer
  ---@field path string
  ---@field line integer
  ---@field s_char integer
  ---@field e_char integer
  ---@field msg string
  local diagnostic = {}

  for line in analysis:gmatch("([^\r\n]+)") do
    local diag_path, diag_line, diag_s_char, diag_msg = line:match(analysis_match)
    if diag_path then
      local analysis_search_reg = diag_msg:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
      local analysis_search_start = analysis:find(analysis_search_reg)
      local error_len_str = analysis:match("%^~+[^\r\n]", analysis_search_start)
      local error_len = 1
      if error_len_str then
        error_len = #error_len_str
      end

      diagnostic.severity = severity
      diagnostic.path = diag_path
      diagnostic.line = tonumber(diag_line) - 1
      diagnostic.s_char = tonumber(diag_s_char) - 1
      diagnostic.e_char = diagnostic.s_char + error_len
      diagnostic.msg = diag_msg

      if diagnostic.s_char < 0 then
        diagnostic.line = diagnostic.line - 1
        diagnostic.s_char = 0
        diagnostic.e_char = 1
      end

      break
    end

    local extern_path, extern_line, extern_msg = line:match("(.-):(%d+):%s+error:%s+([^\r\n]+)")
    if extern_path then
      for l in analysis:gmatch("[^\r\n]+") do
        local extern_analysis_match = "(.-):(%d+):(%d+):%s*from:"
        diag_path, diag_line, diag_s_char = l:match(extern_analysis_match)
        if diag_path then
          local analysis_search_start = analysis:find(extern_analysis_match)
          logger.log(analysis_search_start)
          local error_len_str = analysis:match("%^~+[^\r\n]", analysis_search_start)
          logger.log(type(error_len_str))
          local error_len = 1
          if error_len_str then
            error_len = #error_len_str
          end

          diagnostic.severity = severity
          diagnostic.path = diag_path
          diagnostic.line = tonumber(diag_line) - 1
          diagnostic.s_char = tonumber(diag_s_char) - 1
          diagnostic.e_char = diagnostic.s_char + error_len
          diagnostic.msg = extern_path .. ":" .. extern_line .. ": " .. extern_msg
          break
        end
      end
      break
    end
  end

  return diagnostic
end

---@param documents table<string, string>
---@param current_file string
---@param current_file_path string
---@param current_uri string
---@return boolean
return function(documents, current_file, current_file_path, current_uri)
  local parse_err = false
  current_file = current_file or documents[current_uri]
  local ast, err = analyze_ast(current_file, current_file_path)
  -- for k, v in pairs(context.context.context) do
  --   logger.log(tostring(k) .. "  k")
  --   logger.log(tostring(v) .. "  v")
  -- end
  -- logger.log(ok)
  if not ast then
    -- logger.log(err.message)
    if err.message:match(":%s*error:") then
      local diag = create_diagnostic(err.message, "(.-):(%d+):(%d+):%s+error:%s+([^\r\n]+)", Severity.Error)
      local diagnostic =
        notification.diagnostic(current_uri, diag.line, diag.s_char, diag.e_char, diag.severity, diag.msg, false)
      -- logger.log(diagnostic)
      io.write(diagnostic)
      io.flush()
      parse_err = true
      return parse_err
    elseif err.message:match(":%s*syntax error:") then
      local diag = create_diagnostic(err.message, "(.-):(%d+):(%d+):%s+syntax error:%s+([^\r\n]+)", Severity.Error)
      local diagnostic =
        notification.diagnostic(current_uri, diag.line, diag.s_char, diag.e_char, Severity.Error, diag.msg, false)
      -- logger.log(diagnostic)
      io.write(diagnostic)
      io.flush()
      parse_err = true
      return parse_err
    end
  else
    local diagnostic = notification.diagnostic(current_uri, 0, 0, 0, 0, "", true)
    io.write(diagnostic)
    io.flush()
    return parse_err
  end
  return parse_err
end
