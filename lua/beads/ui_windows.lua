-- Window and buffer management for beads UI
-- Handles creation and management of floating windows and sidebar windows

local error_handling = require("beads.error_handling")
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
      error_handling.safe_api_call(vim.api.nvim_win_close, M.preview_winid, false)
      M.preview_winid = nil
    end
    error_handling.safe_api_call(vim.api.nvim_win_close, M.task_list_winid, false)
    M.task_list_winid = nil
    M.task_list_bufnr = nil
  end
end

--- Create a floating window for task list
--- @return integer|nil Buffer number, or nil on error
--- @return integer|nil Window ID, or nil on error
function M.create_float_window()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Validate dimensions
  local valid, err = error_handling.validate_dimensions(width, height)
  if not valid then
    vim.notify("Cannot create window: " .. err, vim.log.levels.ERROR)
    return nil, nil
  end

  -- Create buffer
  local bufnr, buf_err = error_handling.safe_api_call(vim.api.nvim_create_buf, false, true)
  if not bufnr then
    vim.notify("Failed to create buffer: " .. buf_err, vim.log.levels.ERROR)
    return nil, nil
  end

  -- Set buffer options
  error_handling.safe_api_call(vim.api.nvim_buf_set_option, bufnr, "buftype", "nofile")
  error_handling.safe_api_call(vim.api.nvim_buf_set_option, bufnr, "bufhidden", "hide")
  error_handling.safe_api_call(vim.api.nvim_buf_set_option, bufnr, "modifiable", true)

  -- Create window
  local winid, win_err = error_handling.safe_api_call(vim.api.nvim_open_win, bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    zindex = 50,
  })

  if not winid then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.notify("Failed to create window: " .. win_err, vim.log.levels.ERROR)
    return nil, nil
  end

  -- Set window options
  error_handling.safe_api_call(vim.api.nvim_win_set_option, winid, "cursorline", true)
  error_handling.safe_api_call(vim.api.nvim_win_set_option, winid, "number", false)
  error_handling.safe_api_call(vim.api.nvim_win_set_option, winid, "wrap", false)

  -- Apply theme highlight groups to window
  error_handling.safe_api_call(
    vim.api.nvim_win_set_option,
    winid,
    "winhighlight",
    "Normal:BeadsNormal,Border:BeadsBorder,CursorLine:BeadsTaskListSelected"
  )

  return bufnr, winid
end

--- Create a sidebar window for task list
--- @return integer|nil Buffer number, or nil on error
--- @return integer|nil Window ID, or nil on error
function M.create_sidebar_window()
  -- Get sidebar configuration
  local beads = error_handling.safe_require("beads")
  if not beads then
    vim.notify("Failed to load beads module for sidebar configuration", vim.log.levels.ERROR)
    return nil, nil
  end

  local config = beads.get_config()
  local width = config.sidebar_width or 40
  local position = config.sidebar_position or "left"

  -- Validate width
  if not width or width <= 0 or width > vim.o.columns then
    vim.notify("Invalid sidebar width: " .. tostring(width), vim.log.levels.ERROR)
    return nil, nil
  end

  -- Create buffer
  local bufnr, buf_err = error_handling.safe_api_call(vim.api.nvim_create_buf, false, true)
  if not bufnr then
    vim.notify("Failed to create buffer: " .. buf_err, vim.log.levels.ERROR)
    return nil, nil
  end

  -- Set buffer options
  error_handling.safe_api_call(vim.api.nvim_buf_set_option, bufnr, "buftype", "nofile")
  error_handling.safe_api_call(vim.api.nvim_buf_set_option, bufnr, "bufhidden", "wipe")
  error_handling.safe_api_call(vim.api.nvim_buf_set_option, bufnr, "modifiable", true)

  -- Create vertical split on the specified side
  -- Left sidebar: create split on left with "topleft vsplit"
  -- Right sidebar: create split on right with "botright vsplit"
  local split_cmd = position == "right" and "botright vsplit" or "topleft vsplit"
  local ok, err = pcall(vim.cmd, split_cmd)
  if not ok then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.notify("Failed to create split: " .. tostring(err), vim.log.levels.ERROR)
    return nil, nil
  end

  -- Get the created window and set buffer
  local winid, win_err = error_handling.safe_api_call(vim.api.nvim_get_current_win)
  if not winid then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.notify("Failed to get window: " .. win_err, vim.log.levels.ERROR)
    return nil, nil
  end

  error_handling.safe_api_call(vim.api.nvim_win_set_buf, winid, bufnr)

  -- Set window options
  error_handling.safe_api_call(vim.api.nvim_win_set_option, winid, "cursorline", true)
  error_handling.safe_api_call(vim.api.nvim_win_set_option, winid, "number", false)
  error_handling.safe_api_call(vim.api.nvim_win_set_option, winid, "wrap", false)

  -- Set window width
  error_handling.safe_api_call(vim.api.nvim_win_set_width, winid, width)

  -- Apply theme highlight groups
  error_handling.safe_api_call(
    vim.api.nvim_win_set_option,
    winid,
    "winhighlight",
    "Normal:BeadsNormal,CursorLine:BeadsTaskListSelected"
  )

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
    error_handling.safe_api_call(vim.api.nvim_win_close, M.preview_winid, true)
    M.preview_winid = nil
  end

  -- Create preview buffer
  local bufnr, buf_err = error_handling.safe_api_call(vim.api.nvim_create_buf, false, true)
  if not bufnr then
    vim.notify("Failed to create preview buffer: " .. buf_err, vim.log.levels.ERROR)
    return
  end
  M.preview_bufnr = bufnr

  -- Set buffer options
  error_handling.safe_api_call(vim.api.nvim_buf_set_option, M.preview_bufnr, "buftype", "nofile")
  error_handling.safe_api_call(vim.api.nvim_buf_set_option, M.preview_bufnr, "bufhidden", "wipe")

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

  error_handling.safe_api_call(vim.api.nvim_buf_set_lines, M.preview_bufnr, 0, -1, false, lines)
  error_handling.safe_api_call(vim.api.nvim_buf_set_option, M.preview_bufnr, "modifiable", false)

  -- Create floating window to the right of sidebar
  local width = 50
  local height = math.min(#lines + 2, vim.o.lines - 5)
  local col = math.max(1, vim.o.columns - width - 2)
  local row = 1

  -- Validate dimensions
  local valid, err = error_handling.validate_dimensions(width, height)
  if not valid then
    vim.api.nvim_buf_delete(M.preview_bufnr, { force = true })
    vim.notify("Cannot create preview window: " .. err, vim.log.levels.ERROR)
    return
  end

  local winid, win_err = error_handling.safe_api_call(vim.api.nvim_open_win, M.preview_bufnr, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    zindex = 100,
  })

  if not winid then
    vim.api.nvim_buf_delete(M.preview_bufnr, { force = true })
    vim.notify("Failed to create preview window: " .. win_err, vim.log.levels.ERROR)
    return
  end

  M.preview_winid = winid
  error_handling.safe_api_call(vim.api.nvim_win_set_option, M.preview_winid, "cursorline", true)
end

return M
