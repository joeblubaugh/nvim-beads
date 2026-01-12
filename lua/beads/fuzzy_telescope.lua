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

-- Telescope.nvim fuzzy finder implementation for beads

local M = {}

local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders_module = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

--- Format a task for display
local function format_task_entry(task)
  local status_symbol = (task.status == "closed" or task.status == "complete") and "✓" or "○"
  local priority = task.priority or "P2"
  return string.format("%s [%s] [%s] %s: %s", status_symbol, priority, task.id, task.status or "open", task.title or task.name)
end

--- Open telescope picker for tasks
--- @param tasks table List of task objects
--- @param on_select function Callback when task is selected
function M.find_task(tasks, on_select)
  local picker = pickers.new({}, {
    prompt_title = "Find Beads Task",
    finder = finders_module.new_table({
      results = tasks,
      entry_maker = function(entry)
        return {
          value = entry,
          display = format_task_entry(entry),
          ordinal = (entry.title or entry.name or "") .. " " .. (entry.id or ""),
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          on_select(selection.value)
        end
      end)
      return true
    end,
  })

  picker:find()
end

--- Open telescope picker for status selection
--- @param task table Task object
--- @param on_select function Callback with selected status
function M.find_status(task, on_select)
  local statuses = { "open", "in_progress", "closed" }

  local picker = pickers.new({}, {
    prompt_title = "Select Status (current: " .. (task.status or "open") .. ")",
    finder = finders_module.new_table({
      results = statuses,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          on_select(selection.value)
        end
      end)
      return true
    end,
  })

  picker:find()
end

--- Open telescope picker for priority selection
--- @param task table Task object
--- @param on_select function Callback with selected priority
function M.find_priority(task, on_select)
  local priorities = { "P1", "P2", "P3" }

  local picker = pickers.new({}, {
    prompt_title = "Select Priority (current: " .. (task.priority or "P2") .. ")",
    finder = finders_module.new_table({
      results = priorities,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          on_select(selection.value)
        end
      end)
      return true
    end,
  })

  picker:find()
end

return M
