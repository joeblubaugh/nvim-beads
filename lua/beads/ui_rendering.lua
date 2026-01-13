-- Task rendering and formatting for beads UI
-- Handles task display, tree building, filtering, and highlighting

local M = {}
local utils = require("beads.utils")

--- Check if task is a parent task (has no dots in ID)
--- @param task table Task object
--- @return boolean True if task has no dot in ID (parent)
function M.is_parent_task(task)
  return not task.id:match("%.")
end

--- Get parent ID from a child task ID
--- @param id string Task ID like "nvim-beads-18m.1"
--- @return string|nil Parent ID like "nvim-beads-18m"
function M.get_parent_id(id)
  return id:match("^(.+)%.")
end

--- Format a task for display
--- @param task table Task object
--- @param indent_level number Indentation level (0 for parent, 1+ for children)
--- @return string Formatted task string
function M.format_task(task, indent_level)
  indent_level = indent_level or 0
  local status_symbol = utils.get_status_symbol(task)
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
function M.build_task_tree(task_list)
  local lines = {}
  local task_map = {}
  local children_map = {}
  local displayed = {}

  -- Build maps for quick lookup and organize children
  for _, task in ipairs(task_list) do
    task_map[task.id] = task

    if not M.is_parent_task(task) then
      local parent_id = M.get_parent_id(task.id)
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
    if M.is_parent_task(task) then
      -- Add parent
      table.insert(lines, M.format_task(task, 0))
      displayed[task.id] = true

      -- Add children if any
      if children_map[task.id] then
        for _, child in ipairs(children_map[task.id]) do
          table.insert(lines, M.format_task(child, 1))
          displayed[child.id] = true
        end
      end
    end
  end

  -- Display any remaining tasks (children without their parent in the list, or orphaned tasks)
  for _, task in ipairs(task_list) do
    if not displayed[task.id] then
      -- This is a task that wasn't displayed (likely a child without parent in the filtered list)
      table.insert(lines, M.format_task(task, 0))
      displayed[task.id] = true
    end
  end

  return lines
end

--- Filter tasks by search query
--- @param tasks table List of tasks to search
--- @param query string Search query
--- @return table Filtered tasks
function M.filter_by_search(tasks, query)
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

--- Get highlight group for task based on status
--- @param task table Task object
--- @return string Highlight group name
function M.get_task_highlight(task)
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
function M.get_priority_highlight(priority)
  priority = priority or "P2"
  return "BeadsPriority" .. priority
end

return M
