local logger = require("utils.logger")

local rpc = require("utils.rpc")

local response = {}

---@enum LspErrorCodes
local lsp_error_codes = {
  ParseError = -32700,
  InvalidRequest = -32600,
  MethodNotFound = -32601,
  InvalidParams = -32602,
  InternalError = -32603,
  serverErrorStart = -32099,
  serverErrorEnd = -32000,
  ServerNotInitialized = -32002,
  UnknownErrorCode = -32001,
  RequestFailed = -32803,
}

---@param request_id integer
function response.initialize(request_id)
  local intilaize_response = {
    jsonrpc = "2.0",
    id = request_id,
    result = {
      capabilities = {
        textDocumentSync = 2,
        completionProvider = { triggerCharacters = { ".", ":", "@", "*", "&", "$" } },
        hoverProvider = true,
        renameProvider = true,
        definitionProvider = true,
      },
    },
    serverInfo = {
      name = "nelua_lsp",
      version = "0.0.1",
    },
    -- error = { code = lsp_error_codes.RequestFailed, message = "Failed to initialize server" },
  }
  local encoded_msg, err = rpc.encode(intilaize_response)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
  else
    logger.log(err)
  end
end

---@class CompItem
---@field label string
---@field kind CompItemKind
---@field documentation string
---@field insertTextFormat integer

---@param request_id integer
---@param comp_list CompItem[]
function response.completion(request_id, comp_list)
  local completion_response = {
    jsonrpc = "2.0",
    id = request_id,
    result = comp_list,
    -- error = { code = lsp_error_codes.RequestFailed, message = "Failed to create completion list" },
  }
  local encoded_msg, err = rpc.encode(completion_response)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
  else
    logger.log(err)
  end
end

---@param request_id integer
---@param content string
function response.hover(request_id, content)
  local hover_response = {
    jsonrpc = "2.0",
    id = request_id,
    result = {
      contents = content,
    },
    -- error = { code = lsp_error_codes.RequestFailed, message = "Failed to provide hover" },
  }
  local encoded_msg, err = rpc.encode(hover_response)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
  else
    logger.log(err)
  end
end

---@class Position
---@field line integer
---@field character integer

---@class Range
---@field start Position
---@field end Position

---@class Loc
---@field uri string
---@field range Range

---@param request_id integer
---@param locs? Loc[]
function response.definition(request_id, locs)
  local definition_response = {
    jsonrpc = "2.0",
    id = request_id,
    result = locs or {},
    -- error = { code = lsp_error_codes.RequestFailed, message = "No definition found" },
  }

  local encoded_msg, err = rpc.encode(definition_response)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
  else
    logger.log(err)
  end
end

---@param request_id integer
---@param changes table
function response.rename(request_id, changes)
  local rename_response = {
    jsonrpc = "2.0",
    id = request_id,
    result = {
      changes = changes,
    },
  }

  local encoded_msg, err = rpc.encode(rename_response)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
  else
    logger.log(err)
  end
end

function response.shutdown()
  local shutdown_response = { result = {} }

  local encoded_msg, err = rpc.encode(shutdown_response)
  if encoded_msg then
    io.write(encoded_msg)
    io.flush()
  else
    logger.log(err)
  end
end

return response
