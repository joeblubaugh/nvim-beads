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

-- Theme and highlight configuration for beads plugin

local M = {}

-- Color schemes
local themes = {
  dark = {
    name = "dark",
    bg = "#1e1e1e",
    fg = "#e0e0e0",
    border = "#404040",

    -- Status colors
    open = "#87ceeb",        -- Sky blue for open tasks
    in_progress = "#ffa500", -- Orange for in-progress
    closed = "#90ee90",      -- Light green for closed

    -- Priority colors
    P1 = "#ff6b6b",          -- Red for high priority
    P2 = "#ffd93d",          -- Yellow for medium priority
    P3 = "#6bcf7f",          -- Green for low priority

    -- Sync status
    sync_active = "#4dd0e1", -- Cyan for active sync
    sync_idle = "#90a4ae",   -- Gray for idle
    sync_error = "#ef5350",  -- Red for error

    -- System status
    warning = "#ffb74d",     -- Amber for warnings
    error = "#e57373",       -- Light red for errors
    success = "#81c784",     -- Light green for success

    -- UI elements
    title = "#64b5f6",       -- Light blue for titles
    accent = "#bb86fc",      -- Purple accent
    comment = "#757575",     -- Gray for comments
    modified = "#ffab91",    -- Peach for modified items
  },

  light = {
    name = "light",
    bg = "#ffffff",
    fg = "#1a1a1a",
    border = "#cccccc",

    -- Status colors
    open = "#0066cc",        -- Dark blue for open tasks
    in_progress = "#ff6600", -- Dark orange for in-progress
    closed = "#009933",      -- Dark green for closed

    -- Priority colors
    P1 = "#cc0000",          -- Dark red for high priority
    P2 = "#ffaa00",          -- Dark yellow for medium priority
    P3 = "#00aa00",          -- Dark green for low priority

    -- Sync status
    sync_active = "#0097a7", -- Dark cyan for active sync
    sync_idle = "#616161",   -- Dark gray for idle
    sync_error = "#d32f2f",  -- Dark red for error

    -- System status
    warning = "#f57c00",     -- Dark orange for warnings
    error = "#c62828",       -- Dark red for errors
    success = "#2e7d32",     -- Dark green for success

    -- UI elements
    title = "#0033cc",       -- Dark blue for titles
    accent = "#7700cc",      -- Dark purple accent
    comment = "#9e9e9e",     -- Gray for comments
    modified = "#d84315",    -- Deep orange for modified items
  },
}

-- Highlight groups
local highlight_groups = {
  -- General UI
  "BeadsNormal",
  "BeadsBorder",
  "BeadsTitle",
  "BeadsAccent",

  -- Task status
  "BeadsTaskOpen",
  "BeadsTaskInProgress",
  "BeadsTaskClosed",

  -- Priority
  "BeadsPriorityP1",
  "BeadsPriorityP2",
  "BeadsPriorityP3",

  -- Sync status
  "BeadsSyncActive",
  "BeadsSyncIdle",
  "BeadsSyncError",

  -- System status
  "BeadsWarning",
  "BeadsError",
  "BeadsSuccess",

  -- List items
  "BeadsTaskListItem",
  "BeadsTaskListSelected",
  "BeadsTaskListEven",
  "BeadsTaskListOdd",

  -- Additional
  "BeadsComment",
  "BeadsModified",
}

-- Current theme
local current_theme = "dark"

-- Custom colors (user overrides)
local custom_colors = {}

--- Get theme colors
--- @return table Theme color values
function M.get_colors()
  local theme = themes[current_theme]
  if not theme then
    return themes.dark
  end

  -- Merge custom colors with theme
  return vim.tbl_extend("force", vim.deepcopy(theme), custom_colors)
end

--- Set current theme
--- @param theme_name string Theme name: "dark" or "light"
function M.set_theme(theme_name)
  if themes[theme_name] then
    current_theme = theme_name
    M.apply_theme()
  else
    vim.notify("Unknown theme: " .. theme_name, vim.log.levels.ERROR)
  end
end

--- Get current theme name
--- @return string Current theme name
function M.get_current_theme()
  return current_theme
end

--- Set custom color for a key
--- @param key string Color key (e.g., "P1", "open", "bg")
--- @param color string Hex color code
function M.set_color(key, color)
  custom_colors[key] = color
end

--- Get a specific color
--- @param key string Color key
--- @return string Hex color code
function M.get_color(key)
  local colors = M.get_colors()
  return colors[key] or "#ffffff"
end

--- Apply theme by creating highlight groups
function M.apply_theme()
  local colors = M.get_colors()

  -- Define highlight groups
  local groups = {
    BeadsNormal = {
      fg = colors.fg,
      bg = colors.bg,
    },
    BeadsBorder = {
      fg = colors.border,
    },
    BeadsTitle = {
      fg = colors.title,
      bold = true,
    },
    BeadsAccent = {
      fg = colors.accent,
    },

    -- Task status highlights
    BeadsTaskOpen = {
      fg = colors.open,
    },
    BeadsTaskInProgress = {
      fg = colors.in_progress,
    },
    BeadsTaskClosed = {
      fg = colors.closed,
      strikethrough = true,
    },

    -- Priority highlights
    BeadsPriorityP1 = {
      fg = colors.P1,
      bold = true,
    },
    BeadsPriorityP2 = {
      fg = colors.P2,
    },
    BeadsPriorityP3 = {
      fg = colors.P3,
    },

    -- Sync status highlights
    BeadsSyncActive = {
      fg = colors.sync_active,
      bold = true,
    },
    BeadsSyncIdle = {
      fg = colors.sync_idle,
    },
    BeadsSyncError = {
      fg = colors.sync_error,
      bold = true,
    },

    -- System status highlights
    BeadsWarning = {
      fg = colors.warning,
      bold = true,
    },
    BeadsError = {
      fg = colors.error,
      bold = true,
    },
    BeadsSuccess = {
      fg = colors.success,
      bold = true,
    },

    -- List item highlights
    BeadsTaskListItem = {
      fg = colors.fg,
      bg = colors.bg,
    },
    BeadsTaskListSelected = {
      fg = colors.bg,
      bg = colors.accent,
      bold = true,
    },
    BeadsTaskListEven = {
      fg = colors.fg,
      bg = colors.bg,
    },
    BeadsTaskListOdd = {
      fg = colors.fg,
      bg = string.format("#%02x%02x%02x",
        tonumber(string.sub(colors.bg, 2, 3), 16) + 10,
        tonumber(string.sub(colors.bg, 4, 5), 16) + 10,
        tonumber(string.sub(colors.bg, 6, 7), 16) + 10
      ),
    },

    -- Additional highlights
    BeadsComment = {
      fg = colors.comment,
    },
    BeadsModified = {
      fg = colors.modified,
    },
  }

  -- Apply all highlight groups
  for group, attrs in pairs(groups) do
    local cmd = "highlight " .. group
    for key, value in pairs(attrs) do
      if key == "bold" and value then
        cmd = cmd .. " gui=bold"
      elseif key == "strikethrough" and value then
        cmd = cmd .. " gui=strikethrough"
      elseif key == "fg" then
        cmd = cmd .. " guifg=" .. value
      elseif key == "bg" then
        cmd = cmd .. " guibg=" .. value
      end
    end
    vim.cmd(cmd)
  end
end

--- Auto-detect theme based on background
--- Sets theme to "light" if background is light, "dark" otherwise
function M.auto_detect()
  local bg = vim.o.background
  if bg == "light" then
    M.set_theme("light")
  else
    M.set_theme("dark")
  end
end

--- Get all available themes
--- @return table List of theme names
function M.get_available_themes()
  local available = {}
  for name, _ in pairs(themes) do
    table.insert(available, name)
  end
  return available
end

--- Register theme for use
--- @param name string Theme name
--- @param colors table Color definitions
function M.register_theme(name, colors)
  themes[name] = vim.tbl_extend("force", themes.dark, colors)
end

return M
