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

-- Default configuration
local defaults = {
  keymaps = true,
  auto_sync = true,
  sync_interval = 5000, -- milliseconds
  theme = "dark",        -- color theme: dark or light
  auto_theme = false,    -- auto-detect theme from background
}

-- Global configuration
local config = vim.deepcopy(defaults)

--- Setup the beads plugin with user configuration
--- @param opts table|nil User configuration options
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  -- Load submodules
  require("beads.commands")

  if config.keymaps then
    require("beads.keymaps").setup()
  end

  -- Initialize UI
  require("beads.ui").init()

  -- Initialize fuzzy finder
  require("beads.fuzzy").init()

  -- Initialize theme
  local theme = require("beads.theme")
  if config.auto_theme then
    theme.auto_detect()
  else
    theme.set_theme(config.theme)
  end
  theme.apply_theme()

  -- Setup auto-sync if enabled
  if config.auto_sync then
    local sync = require("beads.sync")
    sync.watch_beads_dir()
    sync.start_auto_sync(config.sync_interval)

    -- Create autocmd group
    vim.api.nvim_create_augroup("nvim_beads", { clear = true })

    -- Clean up on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = "nvim_beads",
      callback = function()
        sync.stop_auto_sync()
      end,
    })
  end
end

--- Get current configuration
--- @return table Current configuration
function M.get_config()
  return config
end

--- Get the beads module for low-level operations
--- @return table Beads module
function M.beads()
  return require("beads.cli")
end

return M
