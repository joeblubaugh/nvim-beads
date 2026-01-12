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

-- Beads CLI integration module
-- Provides Lua interfaces to Beads CLI commands

local M = {}

-- Cache configuration
local cache = {
  ready = { data = nil, time = 0 },
  show = {},  -- Per-task cache
  ttl = 30000,  -- 30 seconds default TTL (milliseconds)
  enabled = true,
  hits = 0,
  misses = 0,
}

--- Enable or disable caching
--- @param enable boolean Whether to enable cache
function M.set_cache_enabled(enable)
  cache.enabled = enable
  if not enable then
    M.clear_cache()
  end
end

--- Set cache TTL
--- @param ttl number Time to live in milliseconds
function M.set_cache_ttl(ttl)
  cache.ttl = ttl
end

--- Clear all cached data
function M.clear_cache()
  cache.ready.data = nil
  cache.ready.time = 0
  cache.show = {}
  cache.hits = 0
  cache.misses = 0
end

--- Get cache statistics
--- @return table Cache statistics
function M.get_cache_stats()
  local total = cache.hits + cache.misses
  local hit_rate = total > 0 and (cache.hits / total) * 100 or 0
  return {
    hits = cache.hits,
    misses = cache.misses,
    total = total,
    hit_rate = string.format("%.1f%%", hit_rate),
  }
end

--- Check if cache entry is still valid
--- @param entry_time number Last update time in milliseconds
--- @param has_data boolean Whether cache has actual data
--- @return boolean True if cache is still valid
local function is_cache_valid(entry_time, has_data)
  if not cache.enabled or not has_data then
    return false
  end
  -- entry_time of 0 means never cached
  if entry_time == 0 then
    return false
  end
  local now = vim.loop.now()
  return (now - entry_time) < cache.ttl
end

--- Check if beads is available
--- @return boolean True if 'bd' command is available
local function is_beads_available()
  local result = os.execute("which bd > /dev/null 2>&1")
  return result == 0 or result == true
end

--- Run a beads command and return parsed JSON output
--- @param cmd string Command to run (e.g., "ready", "show:123")
--- @param args table|nil Optional arguments to pass
--- @return table|nil Parsed JSON output or nil on error
--- @return string|nil Error message if command failed
local function run_command(cmd, args)
  if not is_beads_available() then
    return nil, "Beads CLI not found. Please install 'bd' or ensure it's in your PATH"
  end

  local full_cmd = string.format("bd %s", cmd)
  if args then
    for _, arg in ipairs(args) do
      full_cmd = full_cmd .. " " .. vim.fn.shellescape(arg)
    end
  end

  local handle = io.popen(full_cmd .. " 2>&1")
  if not handle then
    return nil, "Failed to run command: " .. cmd
  end

  local output = handle:read("*a")
  local exit_status = handle:close()

  if output == "" then
    if exit_status then
      return nil, "Command failed with exit code: " .. tostring(exit_status)
    end
    return nil, "No output from command"
  end

  -- Try to parse as JSON
  local ok, result = pcall(vim.json.decode, output)
  if ok then
    return result
  end

  -- Return raw output if not JSON
  return output
end

--- Get list of ready tasks
--- @return table|nil List of tasks
--- @return string|nil Error message
function M.ready()
  -- Check cache first
  if is_cache_valid(cache.ready.time, cache.ready.data ~= nil) then
    cache.hits = cache.hits + 1
    return cache.ready.data
  end

  -- Cache miss, fetch from CLI
  cache.misses = cache.misses + 1
  local result = run_command("ready")

  -- Store in cache (only if we got valid data)
  if cache.enabled and result then
    cache.ready.data = result
    cache.ready.time = vim.loop.now()
  end

  return result
end

--- Show details of a specific task
--- @param id string Task ID
--- @return table|nil Task details
--- @return string|nil Error message
function M.show(id)
  -- Check cache first
  if cache.show[id] and is_cache_valid(cache.show[id].time, cache.show[id].data ~= nil) then
    cache.hits = cache.hits + 1
    return cache.show[id].data
  end

  -- Cache miss, fetch from CLI
  cache.misses = cache.misses + 1
  local result = run_command(string.format("show %s", id))

  -- Store in cache (only if we got valid data)
  if cache.enabled and result then
    if not cache.show[id] then
      cache.show[id] = {}
    end
    cache.show[id].data = result
    cache.show[id].time = vim.loop.now()
  end

  return result
end

--- Create a new task
--- @param title string Task title
--- @param opts table|nil Optional fields (description, priority, etc.)
--- @return table|nil Created task
--- @return string|nil Error message
function M.create(title, opts)
  local args = { title }
  opts = opts or {}

  if opts.description then
    table.insert(args, "--description")
    table.insert(args, opts.description)
  end
  if opts.priority then
    table.insert(args, "--priority")
    table.insert(args, opts.priority)
  end

  local result = run_command("create", args)

  -- Invalidate ready cache when new task is created
  if result then
    cache.ready.data = nil
    cache.ready.time = 0
  end

  return result
end

--- Update a task
--- @param id string Task ID
--- @param opts table Fields to update (status, priority, description, etc.)
--- @return table|nil Updated task
--- @return string|nil Error message
function M.update(id, opts)
  local args = { id }
  opts = opts or {}

  if opts.status then
    table.insert(args, "--status")
    table.insert(args, opts.status)
  end
  if opts.priority then
    table.insert(args, "--priority")
    table.insert(args, opts.priority)
  end
  if opts.description then
    table.insert(args, "--description")
    table.insert(args, opts.description)
  end

  local result = run_command("update", args)

  -- Invalidate caches when task is updated
  if result then
    cache.ready.data = nil
    cache.ready.time = 0
    cache.show[id] = nil
  end

  return result
end

--- Close/complete a task
--- @param id string Task ID
--- @return table|nil Closed task
--- @return string|nil Error message
function M.close(id)
  local result = run_command(string.format("close %s", id))

  -- Invalidate caches when task is closed
  if result then
    cache.ready.data = nil
    cache.ready.time = 0
    cache.show[id] = nil
  end

  return result
end

--- Sync with remote
--- @return boolean True if successful
--- @return string|nil Error message
function M.sync()
  local output = run_command("sync")

  -- Invalidate all caches on sync
  if output then
    M.clear_cache()
  end

  return output ~= nil, output
end

--- Get incremental updates since last sync
--- @param since_time number|nil Unix timestamp for incremental updates
--- @return table|nil Changed tasks or nil on error
--- @return string|nil Error message
function M.get_incremental_updates(since_time)
  local args = {}
  if since_time then
    table.insert(args, "--since")
    table.insert(args, tostring(since_time))
  end

  return run_command("show", args)
end

--- Update a task incrementally (only changed fields)
--- @param id string Task ID
--- @param changed_fields table Only fields that have changed
--- @return table|nil Updated task
--- @return string|nil Error message
function M.update_incremental(id, changed_fields)
  -- Similar to update but only sends changed fields
  local result = M.update(id, changed_fields)

  -- Update specific show cache instead of full invalidation
  if result and cache.enabled then
    cache.show[id] = {
      data = result,
      time = vim.loop.now()
    }
  end

  return result
end

return M
