local M = {}

---Deep copy a table (handles nested tables)
---@param tbl any
---@return any
function M.deepCopy(tbl)
  if type(tbl) ~= "table" then return tbl end
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = M.deepCopy(v)
  end
  return copy
end

return M


