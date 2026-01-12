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

-- Fuzzy finder abstraction module
-- Provides a unified interface for multiple fuzzy finder implementations

local M = {}

-- Available finder implementations
local finders = {
  telescope = nil,
  fzf_lua = nil,
}

-- Current finder backend (defaults to telescope if available)
local current_finder = nil

--- Initialize the fuzzy finder module
--- Attempts to load available fuzzy finder implementations
function M.init()
  -- Try loading telescope
  if pcall(require, "telescope") then
    finders.telescope = require("beads.fuzzy_telescope")
    if not current_finder then
      current_finder = "telescope"
    end
  end

  -- Try loading fzf-lua
  if pcall(require, "fzf-lua") then
    finders.fzf_lua = require("beads.fuzzy_fzf")
    if not current_finder then
      current_finder = "fzf_lua"
    end
  end

  if not current_finder then
    vim.notify("No fuzzy finder available. Install telescope.nvim or fzf-lua", vim.log.levels.WARN)
  end
end

--- Set the preferred fuzzy finder backend
--- @param backend string Finder name: "telescope" or "fzf_lua"
function M.set_finder(backend)
  if finders[backend] then
    current_finder = backend
  else
    vim.notify("Fuzzy finder backend not available: " .. backend, vim.log.levels.ERROR)
  end
end

--- Get the current fuzzy finder backend
--- @return string|nil Current backend name
function M.get_finder()
  return current_finder
end

--- Check if a fuzzy finder is available
--- @return boolean True if at least one finder is available
function M.is_available()
  return current_finder ~= nil
end

--- Open fuzzy finder for tasks
--- @param tasks table List of task objects
--- @param on_select function Callback when task is selected
function M.find_task(tasks, on_select)
  if not current_finder then
    vim.notify("No fuzzy finder available", vim.log.levels.ERROR)
    return
  end

  local finder = finders[current_finder]
  if finder and finder.find_task then
    finder.find_task(tasks, on_select)
  else
    vim.notify("Finder not implemented: " .. current_finder, vim.log.levels.ERROR)
  end
end

--- Open fuzzy finder for task status updates
--- @param task table Task object
--- @param on_select function Callback with selected status
function M.find_status(task, on_select)
  if not current_finder then
    vim.notify("No fuzzy finder available", vim.log.levels.ERROR)
    return
  end

  local finder = finders[current_finder]
  if finder and finder.find_status then
    finder.find_status(task, on_select)
  else
    vim.notify("Finder not implemented: " .. current_finder, vim.log.levels.ERROR)
  end
end

--- Open fuzzy finder for task priority updates
--- @param task table Task object
--- @param on_select function Callback with selected priority
function M.find_priority(task, on_select)
  if not current_finder then
    vim.notify("No fuzzy finder available", vim.log.levels.ERROR)
    return
  end

  local finder = finders[current_finder]
  if finder and finder.find_priority then
    finder.find_priority(task, on_select)
  else
    vim.notify("Finder not implemented: " .. current_finder, vim.log.levels.ERROR)
  end
end

--- Get list of available finders
--- @return table List of available finder names
function M.get_available_finders()
  local available = {}
  for name, impl in pairs(finders) do
    if impl ~= nil then
      table.insert(available, name)
    end
  end
  return available
end

return M
