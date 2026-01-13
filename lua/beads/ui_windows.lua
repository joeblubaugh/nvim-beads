-- Window and buffer management for beads UI
-- Handles creation and management of floating windows and sidebar windows

local M = {}

-- Keep references to created windows
M.task_list_bufnr = nil
M.task_list_winid = nil
M.preview_bufnr = nil
M.preview_winid = nil

--- Close task list windows if they exist
function M.close_windows()
  if M.task_list_winid and vim.api.nvim_win_is_valid(M.task_list_winid) then
    if M.preview_winid and vim.api.nvim_win_is_valid(M.preview_winid) then
      vim.api.nvim_win_close(M.preview_winid, false)
    end
    vim.api.nvim_win_close(M.task_list_winid, false)
    M.task_list_winid = nil
    M.task_list_bufnr = nil
  end
end

--- Create a floating window for task list
--- @return integer Buffer number
--- @return integer Window ID
function M.create_float_window()
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
    zindex = 50,
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
function M.create_sidebar_window()
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

--- Show task preview in a floating window
--- @param task table Task object to preview
function M.show_task_preview(task)
  if not task then
    return
  end

  -- Close existing preview if open
  if M.preview_winid and vim.api.nvim_win_is_valid(M.preview_winid) then
    vim.api.nvim_win_close(M.preview_winid, true)
    M.preview_winid = nil
  end

  -- Create preview buffer
  M.preview_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(M.preview_bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(M.preview_bufnr, "bufhidden", "wipe")

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

  vim.api.nvim_buf_set_lines(M.preview_bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.preview_bufnr, "modifiable", false)

  -- Create floating window to the right of sidebar
  local width = 50
  local height = math.min(#lines + 2, vim.api.nvim_get_option("lines") - 5)
  local col = math.max(1, vim.api.nvim_get_option("columns") - width - 2)
  local row = 1

  M.preview_winid = vim.api.nvim_open_win(M.preview_bufnr, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    zindex = 100,
  })

  vim.api.nvim_win_set_option(M.preview_winid, "cursorline", true)
end

return M
