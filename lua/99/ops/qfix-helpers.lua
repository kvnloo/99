local M = {}

--- @return _99.Search.Result | nil
function M.parse_line(line)
  -- Prefer the complete numeric location: path text may contain colons
  -- (Windows drives, custom filenames), as may the diagnostic message.
  local path, line_no, col_no, notes =
    line:match("^(.-):(%d+):(%d+),%d+,?(.*)$")
  if path then
    return {
      filename = path,
      lnum = tonumber(line_no),
      col = tonumber(col_no),
      text = notes,
    }
  end

  return nil
end

--- @param response string
--- @return _99.Search.Result[]
function M.create_qfix_entries(response)
  local lines = vim.split(response, "\n")
  local qf_list = {} --[[ @as _99.Search.Result[] ]]

  for _, line in ipairs(lines) do
    local res = M.parse_line(line)
    if res then
      table.insert(qf_list, res)
    end
  end
  return qf_list
end

return M
