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
local filters = require("beads.filters")
local theme = require("beads.theme")

-- UI state
local task_list_bufnr = nil
local task_list_winid = nil
local current_tasks = {}

-- Filter state
local filter_state = {
  priority = {},  -- P1, P2, P3
  status = {},    -- open, in_progress, closed
  assignee = {},  -- assignee names
}

--- Initialize UI
function M.init()
  -- Create autocommand group for beads
  vim.api.nvim_create_augroup("beads_ui", { clear = true })
end

--- Get current filter state
--- @return table Filter state with priority, status, and assignee
function M.get_filter_state()
  return vim.deepcopy(filter_state)
end

--- Set filter state
--- @param new_state table New filter state
function M.set_filter_state(new_state)
  if new_state.priority then
    filter_state.priority = new_state.priority
  end
  if new_state.status then
    filter_state.status = new_state.status
  end
  if new_state.assignee then
    filter_state.assignee = new_state.assignee
  end
end

--- Clear all filters
function M.clear_filters()
  filter_state.priority = {}
  filter_state.status = {}
  filter_state.assignee = {}
end

--- Toggle filter value
--- @param filter_type string Filter type: 'priority', 'status', or 'assignee'
--- @param value string Value to toggle
function M.toggle_filter(filter_type, value)
  if not filter_state[filter_type] then
    vim.notify("Invalid filter type: " .. filter_type, vim.log.levels.ERROR)
    return
  end

  local idx = vim.tbl_contains(filter_state[filter_type], value)
  if idx then
    table.remove(filter_state[filter_type], idx)
  else
    table.insert(filter_state[filter_type], value)
  end
end

--- Apply filters from user input string
--- @param filter_string string Filter string (e.g., "priority:P1,status:open")
function M.apply_filter_string(filter_string)
  -- Reset filters
  filter_state.priority = {}
  filter_state.status = {}
  filter_state.assignee = {}

  -- Parse filter string
  for part in string.gmatch(filter_string, "[^,]+") do
    local key, value = string.match(part, "^%s*([^:]+):(.+)$")
    if key and value then
      key = string.gsub(key, "%s+", "")
      value = string.gsub(value, "%s+", "")

      if filter_state[key] then
        table.insert(filter_state[key], value)
      end
    end
  end
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

  -- Apply theme highlight groups to window
  vim.api.nvim_win_set_option(winid, "winhighlight", "Normal:BeadsNormal,Border:BeadsBorder,CursorLine:BeadsTaskListSelected")

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

--- Get highlight group for task based on status
--- @param task table Task object
--- @return string Highlight group name
local function get_task_highlight(task)
  local status = task.status or "open"
  if status == "in_progress" then
    return "BeadsTaskInProgress"
  elseif status == "closed" or status == "complete" then
    return "BeadsTaskClosed"
  else
    return "BeadsTaskOpen"
  end
end

--- Get highlight group for priority
--- @param priority string Priority level
--- @return string Highlight group name
local function get_priority_highlight(priority)
  priority = priority or "P2"
  return "BeadsPriority" .. priority
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

  -- Apply filters to task list
  local filtered_tasks = filters.apply_filters(task_list, filter_state)

  -- Format and display tasks
  local lines = { "# Beads Tasks" }

  -- Show active filters
  if filters.has_active_filters(filter_state) then
    table.insert(lines, "Filters: " .. filters.get_filter_description(filter_state))
  else
    table.insert(lines, "")
  end

  table.insert(lines, "")

  if #filtered_tasks == 0 then
    if #task_list > 0 then
      table.insert(lines, "No tasks match active filters")
    else
      table.insert(lines, "No tasks available")
    end
  else
    for i, task in ipairs(filtered_tasks) do
      table.insert(lines, format_task(task))
    end
    table.insert(lines, "")
    table.insert(lines, "(" .. #filtered_tasks .. "/" .. #task_list .. " tasks)")
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

  -- Filter controls
  vim.keymap.set("n", "f", function()
    vim.ui.input({ prompt = "Filter (priority:P1,status:open,assignee:name): " }, function(input)
      if input and input ~= "" then
        M.apply_filter_string(input)
        M.refresh_task_list()
      end
    end)
  end, opts)

  vim.keymap.set("n", "c", function()
    M.clear_filters()
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

--- Find and select task using fuzzy finder
function M.find_task()
  local fuzzy = require("beads.fuzzy")

  -- Fetch tasks
  local tasks, err = cli.ready()
  if not tasks then
    vim.notify("Failed to load tasks: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Handle both array and object responses
  local task_list = {}
  if type(tasks) == "table" then
    if tasks[1] then
      task_list = tasks
    else
      task_list = { tasks }
    end
  end

  -- Open fuzzy finder
  fuzzy.find_task(task_list, function(task)
    if task then
      M.show_task_detail(task.id)
    end
  end)
end

--- Find and set task status using fuzzy finder
function M.find_task_status()
  local fuzzy = require("beads.fuzzy")

  -- Fetch the currently viewed task (from buffer context)
  vim.ui.input({ prompt = "Enter task ID: " }, function(task_id)
    if not task_id or task_id == "" then
      return
    end

    local task, err = cli.show(task_id)
    if not task then
      vim.notify("Failed to load task: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    fuzzy.find_status(task, function(status)
      if status then
        M.update_task(task_id, "status", status)
      end
    end)
  end)
end

--- Find and set task priority using fuzzy finder
function M.find_task_priority()
  local fuzzy = require("beads.fuzzy")

  -- Fetch the currently viewed task (from buffer context)
  vim.ui.input({ prompt = "Enter task ID: " }, function(task_id)
    if not task_id or task_id == "" then
      return
    end

    local task, err = cli.show(task_id)
    if not task then
      vim.notify("Failed to load task: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    fuzzy.find_priority(task, function(priority)
      if priority then
        M.update_task(task_id, "priority", priority)
      end
    end)
  end)
end

--- Create a task from a template
--- @param template table Template data with resolved variables
function M.create_task_from_template(template)
  if not template or not template.fields then
    vim.notify("Invalid template", vim.log.levels.ERROR)
    return
  end

  local fields = template.fields
  local title = fields.title_template or "New Task"
  local description = fields.description_template or ""
  local priority = fields.priority or "P2"
  local status = fields.status or "open"

  -- Prompt for title if using template
  vim.ui.input({ prompt = "Task title: ", default = title }, function(input_title)
    if not input_title or input_title == "" then
      return
    end

    -- Create the task with CLI
    local ok, result = cli.create(input_title)
    if not ok then
      vim.notify("Failed to create task: " .. (result or "unknown error"), vim.log.levels.ERROR)
      return
    end

    -- Get the created task ID from result if available
    vim.notify("Created task from template: " .. input_title, vim.log.levels.INFO)

    -- Note: In a full implementation, we would also set the description and priority
    -- This would require additional CLI commands or direct database access
  end)
end

-- Preserve UI state for incremental updates
local ui_state = {
  scroll_position = 0,
  selected_task = nil,
  filter_state = {},
}

--- Save current UI state for restoration after incremental updates
function M.save_ui_state()
  return vim.deepcopy(ui_state)
end

--- Restore UI state after updates
--- @param saved_state table Previously saved UI state
function M.restore_ui_state(saved_state)
  if not saved_state then return end
  ui_state = vim.tbl_extend("force", ui_state, saved_state)
end

--- Perform incremental update while preserving UI state
--- @param changed_tasks table Tasks that have changed
function M.update_incremental(changed_tasks)
  if not changed_tasks or #changed_tasks == 0 then
    return
  end

  -- Save UI state
  local saved_state = M.save_ui_state()

  -- Update individual tasks in the list
  for _, task in ipairs(changed_tasks) do
    if task.id then
      -- Update specific task in cache
      cli.update_incremental(task.id, task)
    end
  end

  -- Restore UI state and refresh
  M.restore_ui_state(saved_state)
  vim.notify("Updated " .. #changed_tasks .. " tasks incrementally", vim.log.levels.INFO)
end

return M
