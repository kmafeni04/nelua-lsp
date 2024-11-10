---@param documents table<string, string>
---@param request_params table
---@param current_uri string
---@return string
return function(documents, request_params, current_uri)
  local current_file = ""
  if documents[current_uri] then
    current_file = request_params.contentChanges[1].text
  end
  return current_file
end
