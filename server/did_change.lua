---@param documents table<string, string>
---@param request_params table
---@param current_uri string
---@return string
return function(documents, request_params, current_uri)
  local current_file = ""
  if documents[current_uri] then
    local content_changes = request_params.contentChanges
    for i = 1, #content_changes do
      current_file = content_changes[i].text
    end
  end
  return current_file
end
