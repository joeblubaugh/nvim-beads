-- Utility functions for beads plugin
-- Provides common helpers used across modules

local M = {}

--- Normalize API responses into a consistent table format
--- Handles both array responses and single object responses
--- @param response table|nil The response to normalize
--- @return table Normalized table (array of items, or empty table if nil/empty)
function M.normalize_response(response)
  if not response then
    return {}
  end

  if type(response) ~= "table" then
    return {}
  end

  -- Check if it's already an array (has numeric indices)
  if response[1] then
    return response
  end

  -- Check if it's an object with fields (not an array)
  if next(response) then
    return { response }
  end

  -- Empty table
  return {}
end

--- Check if a table is empty
--- @param tbl table The table to check
--- @return boolean True if empty
function M.is_empty(tbl)
  return next(tbl) == nil
end

--- Deep copy a table (handles nested tables)
--- @param tbl table The table to copy
--- @return table A deep copy of the table
function M.deepcopy(tbl)
  if type(tbl) ~= "table" then
    return tbl
  end
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = M.deepcopy(v)
  end
  return copy
end

--- Merge two tables (shallow merge, right overwrites left)
--- @param left table First table
--- @param right table Second table
--- @return table Merged table
function M.merge_tables(left, right)
  local result = M.deepcopy(left)
  if right then
    for k, v in pairs(right) do
      result[k] = v
    end
  end
  return result
end

--- Check if task is closed/completed
--- @param task table The task to check
--- @return boolean True if task is closed or completed
function M.is_task_closed(task)
  if not task then
    return false
  end
  local status = task.status or "open"
  return status == "closed" or status == "complete"
end

--- Get status symbol for a task
--- @param task table The task to get symbol for
--- @return string Status symbol (○ for open, ✓ for closed)
function M.get_status_symbol(task)
  return M.is_task_closed(task) and "✓" or "○"
end

--- Truncate a string to max length with ellipsis
--- @param str string The string to truncate
--- @param max_len integer Maximum length
--- @return string Truncated string with ellipsis if needed
function M.truncate_string(str, max_len)
  if not str then
    return ""
  end
  max_len = max_len or 65
  if #str > max_len then
    return str:sub(1, max_len - 1) .. "…"
  end
  return str
end

--- Extract task ID from a formatted line
--- Tries multiple patterns to find ID
--- @param line string The line to extract from
--- @return string|nil The extracted task ID or nil
function M.extract_task_id(line)
  if not line then
    return nil
  end

  -- Try bracketed format: [nvim-beads-abc]
  local id = line:match("%[(nvim%-beads%-[^%]]+)%]")
  if id then
    return id
  end

  -- Try any bracketed ID
  id = line:match("%[([^%]]+)%]%s*[^%[]*$")
  if id and id:match("nvim%-beads") then
    return id
  end

  return nil
end

--- Split a string by a separator
--- @param str string The string to split
--- @param sep string The separator
--- @return table Array of parts
function M.split_string(str, sep)
  if not str then
    return {}
  end
  local parts = {}
  for part in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(parts, part)
  end
  return parts
end

--- Get parent task ID from a hierarchical ID
--- @param task_id string The task ID (e.g., "epic-1.1" -> "epic-1")
--- @return string|nil Parent ID or nil if no parent
function M.get_parent_id(task_id)
  if not task_id then
    return nil
  end
  return task_id:match("^(.+)%.")
end

--- Check if a task has a parent (is a child task)
--- @param task_id string The task ID
--- @return boolean True if task has a parent
function M.has_parent(task_id)
  if not task_id then
    return false
  end
  return task_id:match("%.") ~= nil
end

return M
