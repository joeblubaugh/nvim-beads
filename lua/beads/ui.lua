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
local utils = require("beads.utils")
local windows = require("beads.ui_windows")
local rendering = require("beads.ui_rendering")
local editor = require("beads.ui_editor")

-- UI state
local current_tasks = {}
local task_lines_map = {} -- Map from line number to task ID for navigation
local sidebar_visible = false -- Track sidebar visibility for toggle

-- Filter state
local filter_state = {
  priority = {},  -- P1, P2, P3
  status = {},    -- open, in_progress, closed
  assignee = {},  -- assignee names
}

-- Search state
local search_query = nil

-- Sync state
local sync_state = "idle" -- idle, syncing, synced, failed
local last_sync_time = nil -- Timestamp of last successful sync
local sync_spinner_index = 0

--- Initialize UI
function M.init()
  -- Create autocommand group for beads
  vim.api.nvim_create_augroup("beads_ui", { clear = true })
end

--- Toggle sidebar visibility
function M.toggle_sidebar()
  if windows.task_list_winid and vim.api.nvim_win_is_valid(windows.task_list_winid) then
    -- Hide sidebar and preview
    windows.close_windows()
    sidebar_visible = false
    vim.notify("Sidebar hidden", vim.log.levels.INFO)
  else
    -- Show sidebar
    M.show_task_list()
    sidebar_visible = true
    vim.notify("Sidebar shown", vim.log.levels.INFO)
  end
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

--- Set search query for task filtering
--- @param query string|nil Search query (nil to clear)
function M.set_search_query(query)
  search_query = query
end

--- Get current search query
--- @return string|nil Current search query
function M.get_search_query()
  return search_query
end

--- Filter tasks by search query
--- @param tasks table List of tasks to filter
--- @param query string|nil Search query to match against

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

--- Set sync state
--- @param state string Sync state: "idle", "syncing", "synced", or "failed"
function M.set_sync_state(state)
  sync_state = state
  if state == "synced" then
    last_sync_time = os.time()
  end
  M.refresh_task_list()
end

--- Get formatted sync status indicator
--- @return string Sync status text
local function get_sync_indicator()
  if sync_state == "syncing" then
    local spinners = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    sync_spinner_index = (sync_spinner_index + 1) % #spinners
    return spinners[sync_spinner_index + 1] .. " Syncing..."
  elseif sync_state == "synced" then
    if last_sync_time then
      local diff = os.time() - last_sync_time
      local time_str = ""
      if diff < 60 then
        time_str = "now"
      elseif diff < 3600 then
        time_str = math.floor(diff / 60) .. "m ago"
      elseif diff < 86400 then
        time_str = math.floor(diff / 3600) .. "h ago"
      else
        time_str = math.floor(diff / 86400) .. "d ago"
      end
      return "✓ Last sync: " .. time_str
    else
      return "✓ Synced"
    end
  elseif sync_state == "failed" then
    return "✗ Sync failed"
  else
    return "○ Ready"
  end
end


--- Show the task list in a floating window
function M.show_task_list()
  -- Close existing window if open
  if windows.task_list_winid and vim.api.nvim_win_is_valid(windows.task_list_winid) then
    vim.api.nvim_win_close(windows.task_list_winid, true)
  end

  -- Fetch tasks
  local tasks, err = cli.ready()
  if not tasks then
    vim.notify("Failed to load tasks: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Determine which window type to use based on configuration
  local beads = require("beads")
  local config = beads.get_config()

  if config.sidebar_enabled then
    -- Create sidebar window
    windows.task_list_bufnr, windows.task_list_winid = windows.create_sidebar_window()
  else
    -- Create floating window
    windows.task_list_bufnr, windows.task_list_winid = windows.create_float_window()
  end

  current_tasks = utils.normalize_response(tasks)

  -- Apply filters to task list
  local filtered_tasks = filters.apply_filters(current_tasks, filter_state)

  -- Apply search filter
  filtered_tasks = rendering.filter_by_search(filtered_tasks, search_query)

  -- Format and display tasks
  local lines = { "# Beads Tasks" }
  task_lines_map = {} -- Reset the map

  -- Add status bar with task count and filter info
  local status_bar = "Tasks: " .. #filtered_tasks .. "/" .. #current_tasks
  if search_query and search_query ~= "" then
    status_bar = status_bar .. " | Search: '" .. search_query .. "'"
  end
  if filters.has_active_filters(filter_state) then
    status_bar = status_bar .. " | Filters: " .. filters.get_filter_description(filter_state)
  end
  -- Add sync indicator to the right side
  local sync_indicator = get_sync_indicator()
  table.insert(lines, "─ " .. status_bar .. " | " .. sync_indicator .. " " .. string.rep("─", math.max(0, 78 - #status_bar - #sync_indicator - 3)))
  table.insert(lines, "")

  if #filtered_tasks == 0 then
    if #current_tasks > 0 then
      table.insert(lines, "No tasks match active filters")
    else
      table.insert(lines, "No tasks available")
    end
  else
    -- Build and display tree view of tasks
    local tree_lines = rendering.build_task_tree(filtered_tasks)
    local task_idx = 1
    for _, line in ipairs(tree_lines) do
      table.insert(lines, line)
      -- Extract task ID from the line and map it to line number
      -- Task lines have format with brackets around the ID
      local id = line:match("%[(nvim%-beads%-[^%]]+)%]")
      if id then
        task_lines_map[#lines] = id -- Store task ID at this line number
      end
      task_idx = task_idx + 1
    end
    table.insert(lines, "")
    table.insert(lines, "(" .. #filtered_tasks .. "/" .. #current_tasks .. " tasks)")
  end

  vim.api.nvim_buf_set_lines(windows.task_list_bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(windows.task_list_bufnr, "modifiable", false)

  -- Setup keymaps for task list
  local opts = { noremap = true, silent = true, buffer = windows.task_list_bufnr }
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(windows.task_list_winid, true)
    windows.task_list_winid = nil
  end, opts)

  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    -- Extract task ID from line (format: "○ [P2] [id] status: title")
    -- Use specific pattern first to avoid matching title brackets
    local id = line:match("%[(nvim%-beads%-[^%]]+)%]")
    if not id then
      id = line:match("%[([^%]]+)%]%s*[^%[]*$")
    end
    if id then
      -- Close the preview window if open
      if windows.preview_winid and vim.api.nvim_win_is_valid(windows.preview_winid) then
        vim.api.nvim_win_close(windows.preview_winid, true)
        windows.preview_winid = nil
      end
      -- Close the task list window first
      if windows.task_list_winid and vim.api.nvim_win_is_valid(windows.task_list_winid) then
        vim.api.nvim_win_close(windows.task_list_winid, true)
        windows.task_list_winid = nil
      end
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

  vim.keymap.set("n", "d", function()
    local line = vim.api.nvim_get_current_line()
    -- Extract task ID from line (format: "○ [P2] [id] status: title")
    -- Use specific pattern first to avoid matching title brackets
    local id = line:match("%[(nvim%-beads%-[^%]]+)%]")
    if not id then
      id = line:match("%[([^%]]+)%]%s*[^%[]*$")
    end
    if id then
      M.delete_task(id)
    end
  end, opts)

  -- Keyboard navigation with j/k
  vim.keymap.set("n", "j", function()
    -- Move down to next task line
    local current_line = vim.api.nvim_win_get_cursor(windows.task_list_winid)[1]
    local next_line = current_line + 1

    -- Skip non-task lines and find next task line
    while next_line <= vim.api.nvim_buf_line_count(windows.task_list_bufnr) do
      if task_lines_map[next_line] then
        vim.api.nvim_win_set_cursor(windows.task_list_winid, {next_line, 0})
        -- Show preview for the selected task
        local task_id = task_lines_map[next_line]
        if task_id then
          local task = nil
          for _, t in ipairs(current_tasks) do
            if t.id == task_id then
              task = t
              break
            end
          end
          if task then
            windows.show_task_preview(task)
          end
        end
        break
      end
      next_line = next_line + 1
    end
  end, opts)

  vim.keymap.set("n", "k", function()
    -- Move up to previous task line
    local current_line = vim.api.nvim_win_get_cursor(windows.task_list_winid)[1]
    local prev_line = current_line - 1

    -- Skip non-task lines and find previous task line
    while prev_line >= 1 do
      if task_lines_map[prev_line] then
        vim.api.nvim_win_set_cursor(windows.task_list_winid, {prev_line, 0})
        -- Show preview for the selected task
        local task_id = task_lines_map[prev_line]
        if task_id then
          local task = nil
          for _, t in ipairs(current_tasks) do
            if t.id == task_id then
              task = t
              break
            end
          end
          if task then
            windows.show_task_preview(task)
          end
        end
        break
      end
      prev_line = prev_line - 1
    end
  end, opts)

  -- Sidebar width adjustment (only in sidebar mode)
  vim.keymap.set("n", "<", function()
    local beads = require("beads")
    local config = beads.get_config()
    if config.sidebar_enabled then
      local new_width = math.max(20, (config.sidebar_width or 40) - 2)
      config.sidebar_width = new_width
      beads.save_sidebar_config()
      if vim.api.nvim_win_is_valid(windows.task_list_winid) then
        vim.api.nvim_win_set_width(windows.task_list_winid, new_width)
      end
      vim.notify("Sidebar width: " .. new_width, vim.log.levels.INFO)
    end
  end, opts)

  vim.keymap.set("n", ">", function()
    local beads = require("beads")
    local config = beads.get_config()
    if config.sidebar_enabled then
      local new_width = math.min(120, (config.sidebar_width or 40) + 2)
      config.sidebar_width = new_width
      beads.save_sidebar_config()
      if vim.api.nvim_win_is_valid(windows.task_list_winid) then
        vim.api.nvim_win_set_width(windows.task_list_winid, new_width)
      end
      vim.notify("Sidebar width: " .. new_width, vim.log.levels.INFO)
    end
  end, opts)

  -- Toggle sidebar visibility
  vim.keymap.set("n", "t", function()
    M.toggle_sidebar()
  end, opts)

  -- Search/filter functionality
  vim.keymap.set("n", "/", function()
    vim.ui.input({ prompt = "Search tasks (or leave empty to clear): " }, function(input)
      if input == "" or input == nil then
        M.set_search_query(nil)
      else
        M.set_search_query(input)
      end
      -- Refresh task list with new search
      M.refresh_task_list()
    end)
  end, opts)

  -- Clear search with backspace
  vim.keymap.set("n", "<Backspace>", function()
    if search_query and search_query ~= "" then
      M.set_search_query(nil)
      M.refresh_task_list()
      vim.notify("Search cleared", vim.log.levels.INFO)
    end
  end, opts)
end

--- Refresh the task list
function M.refresh_task_list()
  -- Close preview when refreshing
  if windows.preview_winid and vim.api.nvim_win_is_valid(windows.preview_winid) then
    vim.api.nvim_win_close(windows.preview_winid, true)
    windows.preview_winid = nil
  end

  if windows.task_list_winid and vim.api.nvim_win_is_valid(windows.task_list_winid) then
    M.show_task_list()
  else
    vim.notify("Task list not open", vim.log.levels.INFO)
  end
end

--- Show detailed view of a specific task
--- @param id string Task ID
function M.show_task_detail(id)
  editor.show_task_detail(id, M.refresh_task_list)
end

--- Create a new task with interactive buffer editor
--- @param title string|nil Initial task title (optional)
function M.create_task(title)
  editor.create_task(title, M.refresh_task_list)
end

--- Show interactive editor for task creation or editing
--- @param mode string "create", "edit", or "create_child"
--- @param initial_data table Initial task data {title, description, id, priority, from_template, parent_id}
function M.show_task_editor(mode, initial_data)
  editor.show_task_editor(mode, initial_data, M.refresh_task_list)
end

--- Update a task field
--- @param id string Task ID
--- @param field string Field name (status, priority, etc.)
--- @param value string Field value
function M.update_task(id, field, value)
  editor.update_task(id, field, value, M.refresh_task_list)
end

--- Close a task
--- @param id string Task ID
function M.close_task(id)
  editor.close_task(id, M.refresh_task_list)
end

--- Sync with remote
function M.sync()
  M.set_sync_state("syncing")

  -- Run sync in a scheduled function to allow UI update
  vim.schedule(function()
    local ok, result = cli.sync()
    if ok then
      M.set_sync_state("synced")
      vim.notify("Synced with remote", vim.log.levels.INFO)
      -- Refresh task list after successful sync
      M.refresh_task_list()
    else
      M.set_sync_state("failed")
      vim.notify("Failed to sync: " .. (result or "unknown error"), vim.log.levels.ERROR)
    end
  end)
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

  -- Open fuzzy finder with normalized task list
  local task_list = utils.normalize_response(tasks)
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
  editor.create_task_from_template(template, M.refresh_task_list)
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

--- Delete a task
--- @param id string Task ID to delete
function M.delete_task(id)
  editor.delete_task(id, M.refresh_task_list)
end

--- Show child issues of a parent task
--- @param parent_id string Parent task ID
function M.show_task_children(parent_id)
  editor.show_task_children(parent_id, M.refresh_task_list)
end

--- Create a child task under a parent
--- @param parent_id string Parent task ID
--- @param title string|nil Initial task title (optional)
function M.create_child_task(parent_id, title)
  editor.create_child_task(parent_id, title, M.refresh_task_list)
end

return M
