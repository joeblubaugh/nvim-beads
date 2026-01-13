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

-- Error handling utilities for Beads plugin

local M = {}

--- Safely require a module with fallback
--- @param module_path string Module path to require
--- @param fallback any Fallback value if require fails
--- @return any Module or fallback
function M.safe_require(module_path, fallback)
  local ok, result = pcall(require, module_path)
  if not ok then
    vim.notify("Failed to load module: " .. module_path, vim.log.levels.WARN)
    return fallback
  end
  return result
end

--- Safely call a callback function
--- @param callback function Callback to call
--- @param ... any Arguments to pass
--- @return boolean Success status
function M.safe_callback(callback, ...)
  if not callback or type(callback) ~= "function" then
    return false
  end

  local ok, err = pcall(callback, ...)
  if not ok then
    vim.notify("Callback error: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Safely execute vim API call
--- @param api_func function API function to call
--- @param ... any Arguments
--- @return any, string Result and error message
function M.safe_api_call(api_func, ...)
  local ok, result = pcall(api_func, ...)
  if not ok then
    return nil, "API call failed: " .. tostring(result)
  end
  return result, nil
end

--- Validate window dimensions
--- @param width number Window width
--- @param height number Window height
--- @return boolean, string Valid and error message
function M.validate_dimensions(width, height)
  if not width or width <= 0 or width > vim.o.columns then
    return false, "Invalid width: " .. tostring(width)
  end
  if not height or height <= 0 or height > vim.o.lines then
    return false, "Invalid height: " .. tostring(height)
  end
  return true, nil
end

--- Validate ID is not empty
--- @param id string ID to validate
--- @param field_name string Field name for error message
--- @return boolean, string Valid and error message
function M.validate_id(id, field_name)
  field_name = field_name or "ID"
  if not id or id == "" then
    return false, field_name .. " required"
  end
  return true, nil
end

--- Get error message from result or error string
--- @param success boolean Operation success
--- @param result any Result or error
--- @return string Error message
function M.get_error_message(success, result)
  if success then
    return nil
  end
  return tostring(result or "unknown error")
end

return M
