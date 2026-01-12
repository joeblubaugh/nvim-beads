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

-- UI components for beads plugin

local M = {}
local cli = require("beads.cli")

-- UI state
local task_list_bufnr = nil
local task_list_winid = nil
local current_tasks = {}

--- Initialize UI
function M.init()
  -- Create autocommand group for beads
  vim.api.nvim_create_augroup("beads_ui", { clear = true })
end

--- Create a floating window for task list
--- @return integer Buffer number
--- @return integer Window ID
local function create_float_window()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

  -- Create window
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_win_set_option(winid, "cursorline", true)
  vim.api.nvim_win_set_option(winid, "number", false)

  return bufnr, winid
end

--- Format a task for display
--- @param task table Task object
--- @return string Formatted task string
local function format_task(task)
  local status_symbol = (task.status == "closed" or task.status == "complete") and "✓" or "○"
  local priority = task.priority or "P2"
  return string.format("%s [%s] [%s] %s: %s", status_symbol, priority, task.id, task.status or "open", task.title or task.name)
end

--- Show the task list in a floating window
function M.show_task_list()
  -- Close existing window if open
  if task_list_winid and vim.api.nvim_win_is_valid(task_list_winid) then
    vim.api.nvim_win_close(task_list_winid, true)
  end

  -- Fetch tasks
  local tasks, err = cli.ready()
  if not tasks then
    vim.notify("Failed to load tasks: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Create floating window
  task_list_bufnr, task_list_winid = create_float_window()

  -- Handle both array and object responses
  local task_list = {}
  if type(tasks) == "table" then
    if tasks[1] then
      -- Array of tasks
      task_list = tasks
    else
      -- Single task or error
      task_list = { tasks }
    end
  end

  current_tasks = task_list

  -- Format and display tasks
  local lines = { "# Beads Tasks", "" }
  if #task_list == 0 then
    table.insert(lines, "No tasks available")
  else
    for i, task in ipairs(task_list) do
      table.insert(lines, format_task(task))
    end
  end

  vim.api.nvim_buf_set_lines(task_list_bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(task_list_bufnr, "modifiable", false)

  -- Setup keymaps for task list
  local opts = { noremap = true, silent = true, buffer = task_list_bufnr }
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(task_list_winid, true)
    task_list_winid = nil
  end, opts)

  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    -- Extract task ID from line (format: "○ [P2] [id] status: title")
    local id = line:match("%[([^%]]+)%]%s*[^%[]*$")
    if not id then
      id = line:match("%[(nvim%-beads%-[^%]]+)%]")
    end
    if id then
      M.show_task_detail(id)
    end
  end, opts)

  vim.keymap.set("n", "r", function()
    M.refresh_task_list()
  end, opts)
end

--- Refresh the task list
function M.refresh_task_list()
  if task_list_winid and vim.api.nvim_win_is_valid(task_list_winid) then
    M.show_task_list()
  else
    vim.notify("Task list not open", vim.log.levels.INFO)
  end
end

--- Show detailed view of a specific task
--- @param id string Task ID
function M.show_task_detail(id)
  local task, err = cli.show(id)
  if not task then
    vim.notify("Failed to load task: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Create new buffer for task detail
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")

  -- Format task details
  local lines = {
    "# Task: " .. (task.title or task.name or id),
    "",
    "ID: " .. (task.id or id),
    "Status: " .. (task.status or "unknown"),
    "Priority: " .. (task.priority or "P2"),
  }

  if task.description then
    table.insert(lines, "")
    table.insert(lines, "## Description")
    table.insert(lines, task.description)
  end

  if task.comments then
    table.insert(lines, "")
    table.insert(lines, "## Comments")
    for _, comment in ipairs(task.comments) do
      table.insert(lines, "- " .. comment)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Open in new split
  vim.cmd("split")
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
end

--- Create a new task
--- @param title string Task title
function M.create_task(title)
  local ok, result = cli.create(title)
  if ok then
    vim.notify("Created task: " .. title, vim.log.levels.INFO)
  else
    vim.notify("Failed to create task: " .. (result or "unknown error"), vim.log.levels.ERROR)
  end
end

--- Update a task field
--- @param id string Task ID
--- @param field string Field name (status, priority, etc.)
--- @param value string Field value
function M.update_task(id, field, value)
  local opts = {}
  opts[field] = value
  local ok, result = cli.update(id, opts)
  if ok then
    vim.notify("Updated task " .. id, vim.log.levels.INFO)
  else
    vim.notify("Failed to update task: " .. (result or "unknown error"), vim.log.levels.ERROR)
  end
end

--- Close a task
--- @param id string Task ID
function M.close_task(id)
  local ok, result = cli.close(id)
  if ok then
    vim.notify("Closed task " .. id, vim.log.levels.INFO)
  else
    vim.notify("Failed to close task: " .. (result or "unknown error"), vim.log.levels.ERROR)
  end
end

--- Sync with remote
function M.sync()
  local ok, result = cli.sync()
  if ok then
    vim.notify("Synced with remote", vim.log.levels.INFO)
  else
    vim.notify("Failed to sync: " .. (result or "unknown error"), vim.log.levels.ERROR)
  end
end

return M
