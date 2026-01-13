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
local task_lines_map = {} -- Map from line number to task ID for navigation
local sidebar_visible = false -- Track sidebar visibility for toggle
local preview_bufnr = nil -- Preview window buffer
local preview_winid = nil -- Preview window ID

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
  if task_list_winid and vim.api.nvim_win_is_valid(task_list_winid) then
    -- Hide sidebar and preview
    if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
      vim.api.nvim_win_close(preview_winid, false)
      preview_winid = nil
    end
    vim.api.nvim_win_close(task_list_winid, false)
    task_list_winid = nil
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
--- @return table Filtered task list
local function filter_by_search(tasks, query)
  if not query or query == "" then
    return tasks
  end

  local filtered = {}
  -- Convert query to lowercase for case-insensitive search
  local query_lower = query:lower()

  for _, task in ipairs(tasks) do
    local title = (task.title or task.name or ""):lower()
    local id = (task.id or ""):lower()
    local description = (task.description or ""):lower()

    -- Search in title, ID, and description
    if title:find(query_lower, 1, true) or
       id:find(query_lower, 1, true) or
       description:find(query_lower, 1, true) then
      table.insert(filtered, task)
    end
  end

  return filtered
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

--- Create a sidebar window for task list
--- @return integer Buffer number
--- @return integer Window ID
local function create_sidebar_window()
  -- Get sidebar configuration
  local beads = require("beads")
  local config = beads.get_config()
  local width = config.sidebar_width or 40
  local position = config.sidebar_position or "left"

  -- Create buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

  -- Create vertical split on the specified side
  -- Left sidebar: create split on left with "topleft vsplit"
  -- Right sidebar: create split on right with "botright vsplit"
  if position == "right" then
    vim.cmd("botright vsplit")
  else
    vim.cmd("topleft vsplit")
  end

  -- Get the created window and set buffer
  local winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winid, bufnr)

  -- Set window options
  vim.api.nvim_win_set_option(winid, "cursorline", true)
  vim.api.nvim_win_set_option(winid, "number", false)

  -- Set window width
  vim.api.nvim_win_set_width(winid, width)

  -- Apply theme highlight groups
  vim.api.nvim_win_set_option(winid, "winhighlight", "Normal:BeadsNormal,CursorLine:BeadsTaskListSelected")

  return bufnr, winid
end

--- Check if task is a parent task
--- @param task table Task object
--- @return boolean True if task has no dot in ID (parent)
local function is_parent_task(task)
  return not task.id:match("%.")
end

--- Show task preview in a floating window
--- @param task table Task object to preview
local function show_task_preview(task)
  if not task then
    return
  end

  -- Close existing preview if open
  if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
    vim.api.nvim_win_close(preview_winid, true)
    preview_winid = nil
  end

  -- Create preview buffer
  preview_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(preview_bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(preview_bufnr, "bufhidden", "wipe")

  -- Format preview content
  local lines = {
    "# " .. (task.title or task.name or "Task"),
    "",
    "ID: " .. (task.id or ""),
    "Status: " .. (task.status or "open"),
    "Priority: " .. (task.priority or "P2"),
  }

  if task.description and task.description ~= "" then
    table.insert(lines, "")
    table.insert(lines, "## Description")
    -- Split description by newlines
    for desc_line in tostring(task.description):gmatch("[^\n]+") do
      table.insert(lines, desc_line)
    end
  end

  vim.api.nvim_buf_set_lines(preview_bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(preview_bufnr, "modifiable", false)

  -- Create floating window to the right of sidebar
  local width = 50
  local height = math.min(#lines + 2, vim.api.nvim_get_option("lines") - 5)
  local col = math.max(1, vim.api.nvim_get_option("columns") - width - 2)
  local row = 1

  preview_winid = vim.api.nvim_open_win(preview_bufnr, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_win_set_option(preview_winid, "cursorline", true)
end

--- Get parent ID from a child task ID
--- @param id string Task ID like "nvim-beads-18m.1"
--- @return string|nil Parent ID like "nvim-beads-18m"
local function get_parent_id(id)
  return id:match("^(.+)%.")
end

--- Format a task for display
--- @param task table Task object
--- @param indent_level number Indentation level (0 for parent, 1+ for children)
--- @return string Formatted task string
local function format_task(task, indent_level)
  indent_level = indent_level or 0
  local status_symbol = (task.status == "closed" or task.status == "complete") and "✓" or "○"
  local priority = task.priority or "P2"

  -- Use minimal indicator for child tasks (right arrow) instead of indentation
  local child_indicator = ""
  if indent_level > 0 then
    child_indicator = "→ "
  end

  -- Truncate title to fit on single line (estimate max ~80 chars minus metadata)
  -- Remove status text to reduce line length
  local title = task.title or task.name or ""
  local max_title_len = 65
  if #title > max_title_len then
    title = title:sub(1, max_title_len - 1) .. "…"
  end

  return child_indicator .. string.format("%s [%s] [%s] %s", status_symbol, priority, task.id, title)
end

--- Build a hierarchical task list for tree display
--- @param task_list table Flat list of tasks
--- @return table Task lines for display with hierarchy
local function build_task_tree(task_list)
  local lines = {}
  local task_map = {}
  local children_map = {}
  local displayed = {}

  -- Build maps for quick lookup and organize children
  for _, task in ipairs(task_list) do
    task_map[task.id] = task

    if not is_parent_task(task) then
      local parent_id = get_parent_id(task.id)
      if parent_id then
        if not children_map[parent_id] then
          children_map[parent_id] = {}
        end
        table.insert(children_map[parent_id], task)
      end
    end
  end

  -- Display parent tasks with their children
  for _, task in ipairs(task_list) do
    if is_parent_task(task) then
      -- Add parent
      table.insert(lines, format_task(task, 0))
      displayed[task.id] = true

      -- Add children if any
      if children_map[task.id] then
        for _, child in ipairs(children_map[task.id]) do
          table.insert(lines, format_task(child, 1))
          displayed[child.id] = true
        end
      end
    end
  end

  -- Display any remaining tasks (children without their parent in the list, or orphaned tasks)
  for _, task in ipairs(task_list) do
    if not displayed[task.id] then
      -- This is a task that wasn't displayed (likely a child without parent in the filtered list)
      table.insert(lines, format_task(task, 0))
      displayed[task.id] = true
    end
  end

  return lines
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

  -- Determine which window type to use based on configuration
  local beads = require("beads")
  local config = beads.get_config()

  if config.sidebar_enabled then
    -- Create sidebar window
    task_list_bufnr, task_list_winid = create_sidebar_window()
  else
    -- Create floating window
    task_list_bufnr, task_list_winid = create_float_window()
  end

  -- Handle both array and object responses
  local task_list = {}
  if type(tasks) == "table" then
    -- Check if it's an array (has numeric keys) or a single object
    if tasks[1] then
      -- Array of tasks (even if empty, this is correct)
      task_list = tasks
    elseif next(tasks) then
      -- Non-empty object (single task)
      task_list = { tasks }
    else
      -- Empty array or empty object - treat as no tasks
      task_list = {}
    end
  end

  current_tasks = task_list

  -- Apply filters to task list
  local filtered_tasks = filters.apply_filters(task_list, filter_state)

  -- Apply search filter
  filtered_tasks = filter_by_search(filtered_tasks, search_query)

  -- Format and display tasks
  local lines = { "# Beads Tasks" }
  task_lines_map = {} -- Reset the map

  -- Add status bar with task count and filter info
  local status_bar = "Tasks: " .. #filtered_tasks .. "/" .. #task_list
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
    if #task_list > 0 then
      table.insert(lines, "No tasks match active filters")
    else
      table.insert(lines, "No tasks available")
    end
  else
    -- Build and display tree view of tasks
    local tree_lines = build_task_tree(filtered_tasks)
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
    -- Use specific pattern first to avoid matching title brackets
    local id = line:match("%[(nvim%-beads%-[^%]]+)%]")
    if not id then
      id = line:match("%[([^%]]+)%]%s*[^%[]*$")
    end
    if id then
      -- Close the preview window if open
      if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
        vim.api.nvim_win_close(preview_winid, true)
        preview_winid = nil
      end
      -- Close the task list window first
      if task_list_winid and vim.api.nvim_win_is_valid(task_list_winid) then
        vim.api.nvim_win_close(task_list_winid, true)
        task_list_winid = nil
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
    local current_line = vim.api.nvim_win_get_cursor(task_list_winid)[1]
    local next_line = current_line + 1

    -- Skip non-task lines and find next task line
    while next_line <= vim.api.nvim_buf_line_count(task_list_bufnr) do
      if task_lines_map[next_line] then
        vim.api.nvim_win_set_cursor(task_list_winid, {next_line, 0})
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
            show_task_preview(task)
          end
        end
        break
      end
      next_line = next_line + 1
    end
  end, opts)

  vim.keymap.set("n", "k", function()
    -- Move up to previous task line
    local current_line = vim.api.nvim_win_get_cursor(task_list_winid)[1]
    local prev_line = current_line - 1

    -- Skip non-task lines and find previous task line
    while prev_line >= 1 do
      if task_lines_map[prev_line] then
        vim.api.nvim_win_set_cursor(task_list_winid, {prev_line, 0})
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
            show_task_preview(task)
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
      if vim.api.nvim_win_is_valid(task_list_winid) then
        vim.api.nvim_win_set_width(task_list_winid, new_width)
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
      if vim.api.nvim_win_is_valid(task_list_winid) then
        vim.api.nvim_win_set_width(task_list_winid, new_width)
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
  if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
    vim.api.nvim_win_close(preview_winid, true)
    preview_winid = nil
  end

  if task_list_winid and vim.api.nvim_win_is_valid(task_list_winid) then
    M.show_task_list()
  else
    vim.notify("Task list not open", vim.log.levels.INFO)
  end
end

--- Show detailed view of a specific task
--- @param id string Task ID
function M.show_task_detail(id)
  local response, err = cli.show(id)
  if not response then
    vim.notify("Failed to load task: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Handle both array and object responses from bd show
  local task
  if type(response) == "table" then
    if response[1] then
      -- Array response - take first element
      task = response[1]
    elseif next(response) then
      -- Single object response
      task = response
    else
      -- Empty response
      vim.notify("Task not found", vim.log.levels.ERROR)
      return
    end
  end

  if not task then
    vim.notify("Failed to parse task data", vim.log.levels.ERROR)
    return
  end

  -- Format task details
  local lines = {
    "# Task: " .. (task.title or task.name or id),
    "",
    "ID: " .. (task.id or id),
    "Status: " .. (task.status or "unknown"),
    "Priority: " .. (task.priority or "P2"),
  }

  -- Check if task has children
  if is_parent_task(task) then
    local children, _ = cli.list_children(task.id or id)
    local child_count = 0
    if type(children) == "table" then
      if children[1] then
        -- Array response
        child_count = #children
      elseif next(children) then
        -- Single object response
        child_count = 1
      end
    end
    table.insert(lines, "Has Children: Yes (" .. child_count .. ")")
  else
    table.insert(lines, "Has Children: No")
  end

  if task.description then
    table.insert(lines, "")
    table.insert(lines, "## Description")
    -- Split description by newlines to avoid embedding newlines in a single line
    for desc_line in tostring(task.description):gmatch("[^\n]+") do
      table.insert(lines, desc_line)
    end
  end

  if task.comments then
    table.insert(lines, "")
    table.insert(lines, "## Comments")
    for _, comment in ipairs(task.comments) do
      table.insert(lines, "- " .. comment)
    end
  end

  table.insert(lines, "")
  table.insert(lines, "---")
  table.insert(lines, "")
  table.insert(lines, "Keymaps:")
  table.insert(lines, "- 'e' - Edit task")
  table.insert(lines, "- 'd' - Delete task")
  table.insert(lines, "- 'c' - Create child issue (if epic)")
  table.insert(lines, "- 'l' - List child issues (if epic)")
  table.insert(lines, "- 'q' - Close")

  -- Create and configure buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Open in new split
  vim.cmd("split")
  vim.api.nvim_set_current_buf(bufnr)

  -- Add keymap to edit task
  local opts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set("n", "e", function()
    -- Close the detail view
    vim.cmd("quit")
    -- Open editor
    M.show_task_editor("edit", {
      id = task.id or id,
      title = task.title or task.name or "",
      description = task.description or "",
      priority = task.priority or "P2",
    })
  end, opts)

  -- Add 'd' to delete task
  vim.keymap.set("n", "d", function()
    M.delete_task(task.id or id)
  end, opts)

  -- Add 'c' to create child issue
  vim.keymap.set("n", "c", function()
    vim.cmd("quit")
    M.create_child_task(task.id or id, "")
  end, opts)

  -- Add 'l' to list child issues
  vim.keymap.set("n", "l", function()
    vim.cmd("quit")
    M.show_task_children(task.id or id)
  end, opts)

  -- Also add 'q' to close
  vim.keymap.set("n", "q", function()
    vim.cmd("quit")
  end, opts)
end

--- Create a new task with interactive buffer editor
--- @param title string|nil Initial task title (optional)
function M.create_task(title)
  M.show_task_editor("create", {
    title = title or "",
    description = "",
  })
end

--- Parse title, description, and priority from editor buffer lines
local function parse_editor_content(lines)
  local parsed_title = ""
  local parsed_description = ""
  local parsed_priority = "P2"
  local in_title = false
  local in_description = false
  local in_priority = false

  for i, line in ipairs(lines) do
    if line == "## Title" then
      in_title = true
      in_description = false
      in_priority = false
    elseif line == "## Description" then
      in_title = false
      in_description = true
      in_priority = false
    elseif line == "## Priority" then
      in_title = false
      in_description = false
      in_priority = true
    elseif line == "---" then
      break
    elseif in_title and line ~= "" then
      parsed_title = line
      in_title = false
    elseif in_description and line ~= "---" then
      if parsed_description == "" then
        parsed_description = line
      else
        parsed_description = parsed_description .. "\n" .. line
      end
    elseif in_priority and line ~= "" then
      local priority = line:match("^(P[1-3])$")
      if priority then
        parsed_priority = priority
      else
        vim.notify("Invalid priority: " .. line .. " (use P1, P2, or P3)", vim.log.levels.WARN)
      end
      in_priority = false
    end
  end

  return parsed_title, parsed_description, parsed_priority
end

--- Show interactive editor for task creation or editing
--- @param mode string "create" or "edit"
--- @param initial_data table Initial task data {title, description, id, priority, from_template}
function M.show_task_editor(mode, initial_data)
  initial_data = initial_data or {}
  local title = initial_data.title or ""
  local description = initial_data.description or ""
  local task_id = initial_data.id
  local parent_id = initial_data.parent_id
  local priority = initial_data.priority or "P2"
  local from_template = initial_data.from_template or false

  -- Prepare content with instructions
  local content = {}
  if mode == "edit" then
    table.insert(content, "# Task Editor")
  elseif mode == "create_child" then
    table.insert(content, "# Create Child Issue of " .. parent_id)
  else
    table.insert(content, "# Task Creator")
    if from_template then
      table.insert(content, "*From template*")
    end
  end
  table.insert(content, "")
  table.insert(content, "## Title")
  table.insert(content, tostring(title))
  table.insert(content, "")
  table.insert(content, "## Description")
  local desc_str = tostring(description)
  if desc_str ~= "" then
    -- Split description by newlines for multi-line display
    for line in desc_str:gmatch("[^\n]+") do
      table.insert(content, line)
    end
  else
    table.insert(content, "")
  end
  table.insert(content, "")
  table.insert(content, "## Priority")
  table.insert(content, tostring(priority))
  table.insert(content, "")
  table.insert(content, "---")
  table.insert(content, "")
  table.insert(content, "Instructions:")
  table.insert(content, "- Edit title, description, and priority above the --- line")
  table.insert(content, "- Priority must be P1 (high), P2 (medium), or P3 (low)")
  if mode == "create" or mode == "create_child" then
    table.insert(content, "- Press <C-s> to create task")
  else
    table.insert(content, "- Press <C-s> to save changes")
  end
  table.insert(content, "- Press <C-c> or :q to cancel")

  -- Create and configure buffer before defining functions that use it
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

  -- Helper function to handle save/create
  local function handle_save()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local parsed_title, parsed_description, parsed_priority = parse_editor_content(lines)

    -- Validate input
    if parsed_title == "" then
      vim.notify("Title cannot be empty", vim.log.levels.ERROR)
      return
    end

    -- Create or update task
    if mode == "create" then
      local opts = {
        description = parsed_description,
        priority = parsed_priority,
      }
      local result, err = cli.create(parsed_title, opts)
      if not result then
        vim.notify("Failed to create task: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
      end
      local msg = from_template and "Created task from template: " or "Created task: "
      vim.notify(msg .. parsed_title, vim.log.levels.INFO)

      -- Schedule refresh after task is created to update task list
      vim.schedule(function()
        M.refresh_task_list()
      end)
    elseif mode == "create_child" then
      local opts = {
        description = parsed_description,
        priority = parsed_priority,
      }
      local result, err = cli.create_child(parent_id, parsed_title, opts)
      if not result then
        vim.notify("Failed to create child task: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
      end
      vim.notify("Created child task: " .. parsed_title, vim.log.levels.INFO)

      -- Schedule refresh after task is created to update task list
      vim.schedule(function()
        M.refresh_task_list()
      end)
    else
      local update_opts = {}
      if parsed_title ~= title then
        vim.notify("Note: Title cannot be changed after creation", vim.log.levels.WARN)
      end
      if parsed_description ~= description then
        update_opts.description = parsed_description
      end
      if parsed_priority ~= priority then
        update_opts.priority = parsed_priority
      end

      if next(update_opts) then
        local result, err = cli.update(task_id, update_opts)
        if not result then
          vim.notify("Failed to update task: " .. (err or "unknown error"), vim.log.levels.ERROR)
          return
        end
        vim.notify("Updated task: " .. task_id, vim.log.levels.INFO)

        -- Schedule refresh after task is updated to update task list
        vim.schedule(function()
          M.refresh_task_list()
        end)
      end
    end

    -- Close the buffer
    vim.cmd("quit")
  end

  -- Open in a split and display buffer
  vim.cmd("split")
  vim.api.nvim_set_current_buf(bufnr)

  -- Setup keymaps for this buffer
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- Ctrl-S to save/create
  vim.keymap.set("n", "<C-s>", handle_save, opts)
  vim.keymap.set("i", "<C-s>", function()
    vim.cmd("stopinsert")
    handle_save()
  end, opts)

  -- Ctrl-C or :q to cancel
  vim.keymap.set("n", "<C-c>", function()
    vim.cmd("quit")
  end, opts)

  -- Position cursor in title field
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
end

--- Update a task field
--- @param id string Task ID
--- @param field string Field name (status, priority, etc.)
--- @param value string Field value
function M.update_task(id, field, value)
  local opts = {}
  opts[field] = value
  local result, err = cli.update(id, opts)
  if result then
    vim.notify("Updated task " .. id, vim.log.levels.INFO)
    -- Refresh task list after update
    M.refresh_task_list()
  else
    vim.notify("Failed to update task: " .. (err or "unknown error"), vim.log.levels.ERROR)
  end
end

--- Close a task
--- @param id string Task ID
function M.close_task(id)
  local result, err = cli.close(id)
  if result then
    vim.notify("Closed task " .. id, vim.log.levels.INFO)
    -- Refresh task list after closing
    M.refresh_task_list()
  else
    vim.notify("Failed to close task: " .. (err or "unknown error"), vim.log.levels.ERROR)
  end
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

  -- Store priority in global state for use in the editor callback
  -- We'll need to modify the editor to handle priority
  _beads_create_priority = priority

  -- Open editor with template defaults
  M.show_task_editor("create", {
    title = title,
    description = description,
    from_template = true,
    priority = priority,
  })
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
  vim.ui.select({ "No", "Yes" }, { prompt = "Delete task " .. id .. "? This action cannot be undone." }, function(choice)
    if choice == "Yes" then
      local result, err = cli.delete(id, true)
      if result then
        vim.notify("Task deleted: " .. id, vim.log.levels.INFO)
        -- Close detail view if open
        vim.cmd("quit")
        -- Refresh task list
        M.refresh_task_list()
      else
        vim.notify("Failed to delete task: " .. (err or "unknown error"), vim.log.levels.ERROR)
      end
    end
  end)
end

--- Show child issues of a parent task
--- @param parent_id string Parent task ID
function M.show_task_children(parent_id)
  local children, err = cli.list_children(parent_id)
  if not children then
    vim.notify("Failed to load child issues: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Handle both array and object responses
  local child_list = {}
  if type(children) == "table" then
    if children[1] then
      child_list = children
    elseif next(children) then
      child_list = { children }
    else
      child_list = {}
    end
  end

  -- Create new buffer for child issues
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")

  -- Format child issues display
  local lines = {
    "# Child Issues of " .. parent_id,
    "",
    "Press 'p' to go back to parent issue | Press 'q' to close",
    "",
  }

  if #child_list == 0 then
    table.insert(lines, "No child issues found")
  else
    for _, child in ipairs(child_list) do
      local status_symbol = (child.status == "closed" or child.status == "complete") and "✓" or "○"
      local priority = child.priority or "P2"
      table.insert(lines, string.format("%s [%s] [%s] %s: %s", status_symbol, priority, child.id, child.status or "open", child.title or child.name))
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Open in new split
  vim.cmd("split")
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

  -- Add keymaps
  local opts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set("n", "q", function()
    vim.cmd("quit")
  end, opts)

  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    local id = line:match("%[([^%]]+)%]%s*[^%[]*$")
    if not id then
      id = line:match("%[(nvim%-beads%-[^%]]+)%]")
    end
    if id then
      vim.cmd("quit")
      M.show_task_detail(id)
    end
  end, opts)

  -- Add 'p' to navigate to parent task
  vim.keymap.set("n", "p", function()
    vim.cmd("quit")
    M.show_task_detail(parent_id)
  end, opts)
end

--- Create a child task under a parent
--- @param parent_id string Parent task ID
--- @param title string|nil Initial task title (optional)
function M.create_child_task(parent_id, title)
  M.show_task_editor("create_child", {
    parent_id = parent_id,
    title = title or "",
    description = "",
    priority = "P2",
  })
end

return M
