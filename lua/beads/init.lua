local M = {}

-- Plugin version
M.version = "0.1.0"

-- Default configuration
local defaults = {
  keymaps = true,
  auto_sync = true,
  sync_interval = 5000, -- milliseconds
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

  -- Setup auto-sync if enabled
  if config.auto_sync then
    local sync = require("beads.sync")
    sync.watch_beads_dir()
    sync.start_auto_sync(config.sync_interval)

    -- Clean up on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = "beads",
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
