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

-- fzf-lua fuzzy finder implementation for beads

local M = {}

local fzf = require("fzf-lua")

--- Format a task for display
local function format_task_entry(task)
  local status_symbol = (task.status == "closed" or task.status == "complete") and "✓" or "○"
  local priority = task.priority or "P2"
  return string.format("%s [%s] [%s] %s: %s", status_symbol, priority, task.id, task.status or "open", task.title or task.name)
end

--- Open fzf picker for tasks
--- @param tasks table List of task objects
--- @param on_select function Callback when task is selected
function M.find_task(tasks, on_select)
  -- Create list of formatted task entries with original task data
  local entries = {}
  local task_map = {}

  for i, task in ipairs(tasks) do
    local entry = format_task_entry(task)
    table.insert(entries, entry)
    task_map[entry] = task
  end

  fzf.fzf_exec(entries, {
    prompt = "Beads> ",
    preview = "echo {+}",
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          local task = task_map[selected[1]]
          if task then
            on_select(task)
          end
        end
      end,
    },
  })
end

--- Open fzf picker for status selection
--- @param task table Task object
--- @param on_select function Callback with selected status
function M.find_status(task, on_select)
  local statuses = { "open", "in_progress", "closed" }

  fzf.fzf_exec(statuses, {
    prompt = "Select Status (current: " .. (task.status or "open") .. ")> ",
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          on_select(selected[1])
        end
      end,
    },
  })
end

--- Open fzf picker for priority selection
--- @param task table Task object
--- @param on_select function Callback with selected priority
function M.find_priority(task, on_select)
  local priorities = { "P1", "P2", "P3" }

  fzf.fzf_exec(priorities, {
    prompt = "Select Priority (current: " .. (task.priority or "P2") .. ")> ",
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          on_select(selected[1])
        end
      end,
    },
  })
end

return M
