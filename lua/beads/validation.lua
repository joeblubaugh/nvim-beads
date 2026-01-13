-- Copyright 2026 Joe Blubaugh
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Input validation helpers for Beads commands

local M = {}

--- Validate required ID argument
--- @param opts table Command opts
--- @param field_name string Field name for error message (default "Task ID")
--- @return string|nil id Returns ID if valid, nil if invalid (with notification)
function M.require_id(opts, field_name)
  field_name = field_name or "Task ID"
  local id = opts.args
  if id == "" then
    vim.notify(field_name .. " required", vim.log.levels.ERROR)
    return nil
  end
  return id
end

--- Validate required argument with usage message
--- @param opts table Command opts
--- @param usage string Usage message to display
--- @return string|nil Returns arg if valid, nil if invalid
function M.require_arg(opts, usage)
  local arg = opts.args
  if arg == "" then
    vim.notify("Usage: " .. usage, vim.log.levels.ERROR)
    return nil
  end
  return arg
end

--- Validate minimum argument count
--- @param opts table Command opts
--- @param min_count integer Minimum required arguments
--- @param usage string Usage message
--- @return table|nil Returns args if valid, nil if invalid
function M.require_min_args(opts, min_count, usage)
  local args = vim.split(opts.args, " ", { trimempty = true })
  if #args < min_count then
    vim.notify("Usage: " .. usage, vim.log.levels.ERROR)
    return nil
  end
  return args
end

--- Validate enum value
--- @param value string Value to check
--- @param valid_values table List of valid values
--- @param field_name string Field name for error message
--- @return boolean, string|nil True if valid, error message if invalid
function M.validate_enum(value, valid_values, field_name)
  if not value or not vim.tbl_contains(valid_values, value) then
    local msg = field_name .. " must be one of: " .. table.concat(valid_values, ", ")
    vim.notify(msg, vim.log.levels.ERROR)
    return false, msg
  end
  return true, nil
end

--- Validate numeric range
--- @param value number Value to check
--- @param min number Minimum value
--- @param max number Maximum value
--- @param field_name string Field name for error message
--- @return boolean, string|nil True if valid, error message if invalid
function M.validate_range(value, min, max, field_name)
  -- Check if value is numeric
  if not value or type(value) ~= "number" then
    local msg = field_name .. " must be a number"
    vim.notify(msg, vim.log.levels.ERROR)
    return false, msg
  end

  -- Check if value is in range
  if value < min or value > max then
    local msg = field_name .. " must be between " .. min .. " and " .. max
    vim.notify(msg, vim.log.levels.ERROR)
    return false, msg
  end
  return true, nil
end

--- Validate non-empty list
--- @param list table List to check
--- @param message string Message to display if empty
--- @return boolean, string|nil True if valid, error message if invalid
function M.require_non_empty_list(list, message)
  if not list or #list == 0 then
    vim.notify(message, vim.log.levels.WARN)
    return false, message
  end
  return true, nil
end

return M
