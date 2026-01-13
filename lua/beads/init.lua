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

local M = {}

-- Plugin version
M.version = "0.1.0"

-- Safe require function for graceful module loading
local error_handling = require("beads.error_handling")

-- Default configuration
local defaults = {
  keymaps = true,
  auto_sync = false,        -- Disabled by default (causes lag spikes)
  sync_interval = 10000,    -- milliseconds (only used if auto_sync enabled)
  theme = "dark",           -- color theme: dark or light
  auto_theme = false,       -- auto-detect theme from background
  sidebar_enabled = false,  -- Use sidebar instead of floating window
  sidebar_position = "left", -- Position: "left" or "right"
  sidebar_width = 40,       -- Width of sidebar in columns
}

-- Global configuration
local config = vim.deepcopy(defaults)

--- Get the path to the sidebar config file
--- @return string Path to config file
local function get_sidebar_config_path()
  local home = vim.env.HOME or vim.fn.expand("~")
  return home .. "/.cache/nvim-beads-sidebar.json"
end

--- Load saved sidebar configuration from file
--- @return table|nil Saved config or nil if not found
local function load_sidebar_config()
  local config_path = get_sidebar_config_path()
  local ok, result = pcall(vim.fn.readfile, config_path)
  if not ok then
    return nil
  end

  if #result == 0 then
    return nil
  end

  local ok_json, config_data = pcall(vim.json.decode, table.concat(result, ""))
  if not ok_json then
    return nil
  end

  return config_data
end

--- Save sidebar configuration to file
--- @param sidebar_config table Configuration to save
local function save_sidebar_config(sidebar_config)
  local config_path = get_sidebar_config_path()
  local config_json = vim.json.encode(sidebar_config)

  -- Ensure cache directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(config_path, ":h"), "p")

  local ok = pcall(vim.fn.writefile, { config_json }, config_path)
  return ok
end

--- Setup the beads plugin with user configuration
--- @param opts table|nil User configuration options
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  -- Load and apply saved sidebar configuration
  local saved_sidebar = load_sidebar_config()
  if saved_sidebar then
    if saved_sidebar.sidebar_enabled ~= nil then
      config.sidebar_enabled = saved_sidebar.sidebar_enabled
    end
    if saved_sidebar.sidebar_position then
      config.sidebar_position = saved_sidebar.sidebar_position
    end
    if saved_sidebar.sidebar_width then
      config.sidebar_width = saved_sidebar.sidebar_width
    end
  end

  -- Load submodules with safe requires
  local commands = error_handling.safe_require("beads.commands")
  if not commands then
    vim.notify("Warning: Failed to load beads commands module", vim.log.levels.WARN)
  end

  if config.keymaps then
    local keymaps = error_handling.safe_require("beads.keymaps")
    if keymaps and keymaps.setup then
      error_handling.safe_callback(keymaps.setup)
    else
      vim.notify("Warning: Failed to load beads keymaps module", vim.log.levels.WARN)
    end
  end

  -- Initialize UI
  local ui = error_handling.safe_require("beads.ui")
  if ui and ui.init then
    error_handling.safe_callback(ui.init)
  else
    vim.notify("Warning: Failed to load beads UI module", vim.log.levels.WARN)
  end

  -- Initialize fuzzy finder
  local fuzzy = error_handling.safe_require("beads.fuzzy")
  if fuzzy and fuzzy.init then
    error_handling.safe_callback(fuzzy.init)
  else
    vim.notify("Warning: Failed to load beads fuzzy module", vim.log.levels.WARN)
  end

  -- Initialize theme
  local theme = error_handling.safe_require("beads.theme")
  if theme then
    if config.auto_theme and theme.auto_detect then
      error_handling.safe_callback(theme.auto_detect)
    elseif theme.set_theme then
      error_handling.safe_callback(theme.set_theme, config.theme)
    end
    if theme.apply_theme then
      error_handling.safe_callback(theme.apply_theme)
    end
  else
    vim.notify("Warning: Failed to load beads theme module", vim.log.levels.WARN)
  end

  -- Setup auto-sync if enabled
  if config.auto_sync then
    local sync = error_handling.safe_require("beads.sync")
    if not sync then
      vim.notify("Warning: Failed to load beads sync module - auto-sync disabled", vim.log.levels.WARN)
    else
      if sync.watch_beads_dir then
        error_handling.safe_callback(sync.watch_beads_dir)
      end
      if sync.start_auto_sync then
        error_handling.safe_callback(sync.start_auto_sync, config.sync_interval)
      end

      -- Create autocmd group
      vim.api.nvim_create_augroup("nvim_beads", { clear = true })

      -- Clean up on exit
      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = "nvim_beads",
        callback = function()
          if sync and sync.stop_auto_sync then
            error_handling.safe_callback(sync.stop_auto_sync)
          end
        end,
      })
    end
  end
end

--- Get current configuration
--- @return table Current configuration
function M.get_config()
  return config
end

--- Get the beads module for low-level operations
--- @return table Beads module or nil if not available
function M.beads()
  return error_handling.safe_require("beads.cli")
end

--- Save sidebar configuration for persistence
--- @return boolean True if save was successful
function M.save_sidebar_config()
  local sidebar_config = {
    sidebar_enabled = config.sidebar_enabled,
    sidebar_position = config.sidebar_position,
    sidebar_width = config.sidebar_width,
  }
  return save_sidebar_config(sidebar_config)
end

return M
