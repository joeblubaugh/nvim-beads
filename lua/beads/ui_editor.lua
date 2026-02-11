-- Task editor interface for beads UI
-- Handles task creation, editing, deletion, and detail viewing

local M = {}
local error_handling = require("beads.error_handling")
local cli = require("beads.cli")
local utils = require("beads.utils")
local rendering = require("beads.ui_rendering")

--- Parse title, description, priority, design, and notes from editor buffer lines
local function parse_editor_content(lines)
  local parsed_title = ""
  local parsed_description = ""
  local parsed_priority = "P2"
  local parsed_design = ""
  local parsed_notes = ""
  local in_title = false
  local in_description = false
  local in_priority = false
  local in_design = false
  local in_notes = false

  for i, line in ipairs(lines) do
    if line == "## Title" then
      in_title = true
      in_description = false
      in_priority = false
      in_design = false
      in_notes = false
    elseif line == "## Description" then
      in_title = false
      in_description = true
      in_priority = false
      in_design = false
      in_notes = false
    elseif line == "## Priority" then
      in_title = false
      in_description = false
      in_priority = true
      in_design = false
      in_notes = false
    elseif line == "## Design" then
      in_title = false
      in_description = false
      in_priority = false
      in_design = true
      in_notes = false
    elseif line == "## Notes" then
      in_title = false
      in_description = false
      in_priority = false
      in_design = false
      in_notes = true
    elseif in_title and line ~= "" then
      parsed_title = line
      in_title = false
    elseif in_description and line ~= "" then
      parsed_description = (parsed_description == "" and line or parsed_description .. "\n" .. line)
    elseif in_priority and line ~= "" then
      parsed_priority = line
      in_priority = false
    elseif in_design and line ~= "" then
      parsed_design = (parsed_design == "" and line or parsed_design .. "\n" .. line)
    elseif in_notes and line ~= "" then
      parsed_notes = (parsed_notes == "" and line or parsed_notes .. "\n" .. line)
    end
  end

  return parsed_title, parsed_description, parsed_priority, parsed_design, parsed_notes
end

--- Show detailed view of a specific task
--- @param id string Task ID
--- @param refresh_callback function Function to call to refresh task list
function M.show_task_detail(id, refresh_callback)
  local response, err = cli.show(id)
  if not response then
    vim.notify("Failed to load task: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Normalize response and get first task
  local task_list = utils.normalize_response(response)
  if #task_list == 0 then
    vim.notify("Task not found", vim.log.levels.ERROR)
    return
  end
  local task = task_list[1]

  -- Format task details
  local lines = {
    "# Task: " .. (task.title or task.name or id),
    "",
    "ID: " .. (task.id or id),
    "Status: " .. (task.status or "unknown"),
    "Priority: " .. (task.priority or "P2"),
  }

  -- Check if task has children
  if rendering.is_parent_task(task) then
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

  if task.design and task.design ~= "" then
    table.insert(lines, "")
    table.insert(lines, "## Design")
    for design_line in tostring(task.design):gmatch("[^\n]+") do
      table.insert(lines, design_line)
    end
  end

  if task.notes and task.notes ~= "" then
    table.insert(lines, "")
    table.insert(lines, "## Notes")
    for notes_line in tostring(task.notes):gmatch("[^\n]+") do
      table.insert(lines, notes_line)
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
      design = task.design or "",
      notes = task.notes or "",
    }, refresh_callback)
  end, opts)

  -- Add 'd' to delete task
  vim.keymap.set("n", "d", function()
    M.delete_task(task.id or id, refresh_callback)
  end, opts)

  -- Add 'c' to create child issue
  vim.keymap.set("n", "c", function()
    vim.cmd("quit")
    M.create_child_task(task.id or id, "", refresh_callback)
  end, opts)

  -- Add 'l' to list child issues
  vim.keymap.set("n", "l", function()
    vim.cmd("quit")
    M.show_task_children(task.id or id, refresh_callback)
  end, opts)

  -- Also add 'q' to close
  vim.keymap.set("n", "q", function()
    vim.cmd("quit")
  end, opts)
end

--- Create a new task with interactive buffer editor
--- @param title string|nil Initial task title (optional)
--- @param refresh_callback function Function to call to refresh task list
function M.create_task(title, refresh_callback)
  M.show_task_editor("create", {
    title = title or "",
    description = "",
  }, refresh_callback)
end

--- Show interactive editor for task creation or editing
--- @param mode string "create", "edit", or "create_child"
--- @param initial_data table Initial task data {title, description, id, priority, from_template, parent_id}
--- @param refresh_callback function Function to call to refresh task list
function M.show_task_editor(mode, initial_data, refresh_callback)
  initial_data = initial_data or {}
  local title = initial_data.title or ""
  local description = initial_data.description or ""
  local task_id = initial_data.id
  local parent_id = initial_data.parent_id
  local priority = initial_data.priority or "P2"
  local from_template = initial_data.from_template or false
  local design = initial_data.design or ""
  local notes = initial_data.notes or ""

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
  table.insert(content, "## Design")
  local design_str = tostring(design)
  if design_str ~= "" then
    for line in design_str:gmatch("[^\n]+") do
      table.insert(content, line)
    end
  else
    table.insert(content, "")
  end
  table.insert(content, "")
  table.insert(content, "## Notes")
  local notes_str = tostring(notes)
  if notes_str ~= "" then
    for line in notes_str:gmatch("[^\n]+") do
      table.insert(content, line)
    end
  else
    table.insert(content, "")
  end
  table.insert(content, "")
  table.insert(content, "---")
  table.insert(content, "")
  table.insert(content, "Instructions:")
  table.insert(content, "- Edit title, description, priority, design, and notes above the --- line")
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
    local parsed_title, parsed_description, parsed_priority, parsed_design, parsed_notes = parse_editor_content(lines)

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
        design = parsed_design,
        notes = parsed_notes,
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
        error_handling.safe_callback(refresh_callback)
      end)
    elseif mode == "create_child" then
      local opts = {
        description = parsed_description,
        priority = parsed_priority,
        design = parsed_design,
        notes = parsed_notes,
      }
      local result, err = cli.create_child(parent_id, parsed_title, opts)
      if not result then
        vim.notify("Failed to create child task: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
      end
      vim.notify("Created child task: " .. parsed_title, vim.log.levels.INFO)

      -- Schedule refresh after task is created to update task list
      vim.schedule(function()
        error_handling.safe_callback(refresh_callback)
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
      if parsed_design ~= design then
        update_opts.design = parsed_design
      end
      if parsed_notes ~= notes then
        update_opts.notes = parsed_notes
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
          error_handling.safe_callback(refresh_callback)
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
--- @param refresh_callback function Function to call to refresh task list
function M.update_task(id, field, value, refresh_callback)
  local opts = {}
  opts[field] = value
  local result, err = cli.update(id, opts)
  if result then
    vim.notify("Updated task " .. id, vim.log.levels.INFO)
    -- Refresh task list after update
    error_handling.safe_callback(refresh_callback)
  else
    vim.notify("Failed to update task: " .. (err or "unknown error"), vim.log.levels.ERROR)
  end
end

--- Close a task
--- @param id string Task ID
--- @param refresh_callback function Function to call to refresh task list
function M.close_task(id, refresh_callback)
  local result, err = cli.close(id)
  if result then
    vim.notify("Closed task " .. id, vim.log.levels.INFO)
    -- Refresh task list after closing
    error_handling.safe_callback(refresh_callback)
  else
    vim.notify("Failed to close task: " .. (err or "unknown error"), vim.log.levels.ERROR)
  end
end

--- Create a task from a template
--- @param template table Template data with resolved variables
--- @param refresh_callback function Function to call to refresh task list
function M.create_task_from_template(template, refresh_callback)
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
  }, refresh_callback)
end

--- Delete a task
--- @param id string Task ID to delete
--- @param refresh_callback function Function to call to refresh task list
function M.delete_task(id, refresh_callback)
  vim.ui.select({ "No", "Yes" }, { prompt = "Delete task " .. id .. "? This action cannot be undone." }, function(choice)
    if choice == "Yes" then
      local result, err = cli.delete(id, true)
      if result then
        vim.notify("Task deleted: " .. id, vim.log.levels.INFO)
        -- Close detail view if open
        vim.cmd("quit")
        -- Refresh task list
        error_handling.safe_callback(refresh_callback)
      else
        vim.notify("Failed to delete task: " .. (err or "unknown error"), vim.log.levels.ERROR)
      end
    end
  end)
end

--- Show child issues of a parent task
--- @param parent_id string Parent task ID
--- @param refresh_callback function Function to call to refresh task list
function M.show_task_children(parent_id, refresh_callback)
  local children, err = cli.list_children(parent_id)
  if not children then
    vim.notify("Failed to load child issues: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  -- Normalize child issues response
  local child_list = utils.normalize_response(children)

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
      local status_symbol = utils.get_status_symbol(child)
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
      M.show_task_detail(id, refresh_callback)
    end
  end, opts)

  vim.keymap.set("n", "p", function()
    vim.cmd("quit")
    M.show_task_detail(parent_id, refresh_callback)
  end, opts)
end

--- Create a child task
--- @param parent_id string Parent task ID
--- @param title string|nil Initial task title (optional)
--- @param refresh_callback function Function to call to refresh task list
function M.create_child_task(parent_id, title, refresh_callback)
  M.show_task_editor("create_child", {
    parent_id = parent_id,
    title = title or "",
    description = "",
    priority = "P2",
  }, refresh_callback)
end

return M
