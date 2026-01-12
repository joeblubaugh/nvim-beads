-- Real-time sync with Beads daemon

local M = {}
local cli = require("beads.cli")

-- Sync state
local sync_timer = nil
local is_syncing = false
local last_sync_time = 0
local sync_callbacks = {}

--- Register a callback to be called on sync
--- @param callback function Function to call when sync completes
function M.on_sync(callback)
  table.insert(sync_callbacks, callback)
end

--- Perform sync with Beads daemon
--- @return boolean True if sync successful
function M.sync()
  if is_syncing then
    return false
  end

  is_syncing = true
  local ok, err = cli.sync()
  is_syncing = false

  if ok then
    last_sync_time = os.time()
    -- Call registered callbacks
    for _, callback in ipairs(sync_callbacks) do
      pcall(callback)
    end
  else
    vim.notify("Sync failed: " .. (err or "unknown error"), vim.log.levels.WARN)
  end

  return ok
end

--- Start periodic sync with the daemon
--- @param interval number Interval in milliseconds
function M.start_auto_sync(interval)
  if sync_timer then
    sync_timer:stop()
  end

  sync_timer = vim.loop.new_timer()
  sync_timer:start(
    interval,
    interval,
    vim.schedule_wrap(function()
      M.sync()
    end)
  )
end

--- Stop periodic sync
function M.stop_auto_sync()
  if sync_timer then
    sync_timer:stop()
    sync_timer:close()
    sync_timer = nil
  end
end

--- Watch .beads directory for changes
--- @return boolean True if watching started successfully
function M.watch_beads_dir()
  -- Get beads directory path (usually .beads in git root)
  local cwd = vim.fn.getcwd()
  local beads_dir = cwd .. "/.beads"

  -- Check if directory exists
  local stat = vim.loop.fs_stat(beads_dir)
  if not stat or stat.type ~= "directory" then
    vim.notify("Beads directory not found: " .. beads_dir, vim.log.levels.WARN)
    return false
  end

  -- Create a file watcher for the beads directory
  -- This is a basic implementation; a more robust version would use libnotify or similar
  local debounce_timer = nil

  local function on_change()
    if debounce_timer then
      debounce_timer:stop()
      debounce_timer:close()
    end

    debounce_timer = vim.loop.new_timer()
    debounce_timer:start(500, 0, vim.schedule_wrap(function()
      M.sync()
      debounce_timer:close()
      debounce_timer = nil
    end))
  end

  -- In a real implementation, we would use vim.loop.fs_event()
  -- For now, we rely on periodic sync configured in auto_sync

  return true
end

--- Get time since last sync
--- @return number Seconds since last sync
function M.time_since_last_sync()
  if last_sync_time == 0 then
    return -1
  end
  return os.time() - last_sync_time
end

--- Check if currently syncing
--- @return boolean True if sync in progress
function M.is_syncing()
  return is_syncing
end

return M
