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

-- Async operations wrapper for beads CLI commands

local M = {}

local cli = require("beads.cli")
local progress = require("beads.progress")

-- Active operations tracking
local operations = {
  active = {},
  completed = {},
  failed = {},
  queue = {},
}

-- Operation counter for unique IDs
local operation_counter = 0

-- Configuration
local config = {
  max_concurrent = 3,
  queue_enabled = true,
  default_timeout = 30000,      -- milliseconds
  retry_enabled = false,
  retry_max_attempts = 3,
  notify_on_complete = true,
  notify_on_error = true,
}

--- Create a unique operation ID
--- @return string Operation ID
local function create_operation_id()
  operation_counter = operation_counter + 1
  return "op_" .. operation_counter
end

--- Wrap CLI function call in async operation
--- @param name string Operation name
--- @param fn function CLI function to call
--- @param args table Arguments to pass to function
--- @param on_complete function Callback on completion (optional)
--- @return string Operation ID
function M.run(name, fn, args, on_complete)
  args = args or {}
  local op_id = create_operation_id()

  -- Create operation with progress tracking
  local operation = {
    id = op_id,
    name = name,
    status = "running",
    start_time = vim.fn.reltime(),
    on_complete = on_complete,
  }

  -- Create progress tracker for the operation
  progress.create_operation(op_id, name)

  operations.active[op_id] = operation

  -- Run in a timer to avoid blocking
  vim.loop.new_timer():start(0, 0, function()
    vim.schedule(function()
      local success, result = pcall(fn, unpack(args))

      operation.status = success and "completed" or "failed"
      operation.end_time = vim.fn.reltime()
      operation.result = result
      operation.success = success

      -- Update progress tracker with result
      if success then
        progress.succeed_operation(op_id, result)
      else
        progress.fail_operation(op_id, result)
      end

      -- Move to completed/failed
      operations.active[op_id] = nil
      if success then
        operations.completed[op_id] = operation
      else
        operations.failed[op_id] = operation
      end

      -- Send notification
      notify_result(operation)

      -- Call completion callback
      if operation.on_complete then
        operation.on_complete(success, result)
      end

      -- Process queue to handle any pending operations
      M.process_queue()
    end)
  end)

  return op_id
end

--- Wait for operation to complete
--- @param op_id string Operation ID
--- @param timeout integer Timeout in milliseconds (optional, default 30000)
--- @return boolean Success status
--- @return any Result value
function M.wait(op_id, timeout)
  timeout = timeout or 30000
  local start = vim.fn.reltime()

  while true do
    local op = operations.active[op_id] or operations.completed[op_id] or operations.failed[op_id]

    if not op then
      return false, "Operation not found"
    end

    if op.status ~= "running" then
      return op.success, op.result
    end

    -- Check timeout
    local elapsed = math.floor(vim.fn.reltimeMs(vim.fn.reltime(start)))
    if elapsed > timeout then
      return false, "Operation timed out"
    end

    vim.loop.sleep(100)
  end
end

--- Get operation status
--- @param op_id string Operation ID
--- @return table Operation status info
function M.get_status(op_id)
  local op = operations.active[op_id] or operations.completed[op_id] or operations.failed[op_id]
  if not op then
    return nil
  end

  -- Merge with progress tracker info
  local progress_info = progress.get_operation(op_id)
  return {
    id = op.id,
    name = op.name,
    status = op.status,
    start_time = op.start_time,
    end_time = op.end_time,
    success = op.success,
    result = op.result,
    elapsed = progress_info and progress_info.elapsed or M.get_elapsed(op_id),
  }
end

--- Get elapsed time for operation
--- @param op_id string Operation ID
--- @return integer Elapsed time in milliseconds
function M.get_elapsed(op_id)
  -- Try to get from progress tracker first
  local progress_elapsed = progress.get_elapsed(op_id)
  if progress_elapsed and progress_elapsed > 0 then
    return progress_elapsed
  end

  -- Fallback to operation tracking
  local op = operations.active[op_id] or operations.completed[op_id] or operations.failed[op_id]
  if not op then
    return 0
  end

  local end_time = op.end_time or vim.fn.reltime()
  return math.floor(vim.fn.reltimeMs(vim.fn.reltime(op.start_time, end_time)))
end

--- Get all active operations
--- @return table List of active operation IDs
function M.get_active()
  local active = {}
  -- Get from operations tracking
  for op_id, _ in pairs(operations.active) do
    table.insert(active, op_id)
  end
  -- Also check progress trackers for running operations
  local progress_active = progress.get_active()
  for _, op_id in ipairs(progress_active) do
    if not vim.tbl_contains(active, op_id) then
      table.insert(active, op_id)
    end
  end
  return active
end

--- Cancel an operation (best effort)
--- @param op_id string Operation ID
function M.cancel(op_id)
  local op = operations.active[op_id]
  if op then
    op.status = "cancelled"
    operations.active[op_id] = nil
    operations.failed[op_id] = op
  end
end

--- Clear completed operations
function M.clear_completed()
  -- Also clear completed progress trackers
  for op_id, _ in pairs(operations.completed) do
    progress.clear(op_id)
  end
  operations.completed = {}
end

--- Clear failed operations
function M.clear_failed()
  -- Also clear failed progress trackers
  for op_id, _ in pairs(operations.failed) do
    progress.clear(op_id)
  end
  operations.failed = {}
end

--- Clear all history (keeps active operations)
function M.clear_history()
  M.clear_completed()
  M.clear_failed()
end

--- Get operation statistics
--- @return table Statistics
function M.get_stats()
  local async_stats = {
    active = 0,
    completed = 0,
    failed = 0,
  }

  for _ in pairs(operations.active) do
    async_stats.active = async_stats.active + 1
  end

  for _ in pairs(operations.completed) do
    async_stats.completed = async_stats.completed + 1
  end

  for _ in pairs(operations.failed) do
    async_stats.failed = async_stats.failed + 1
  end

  -- Also get progress tracking stats for comparison
  local progress_stats = progress.get_summary()

  return {
    active = async_stats.active,
    completed = async_stats.completed,
    failed = async_stats.failed,
    total = async_stats.active + async_stats.completed + async_stats.failed,
    progress_stats = progress_stats,
  }
end

--- Async wrapper for cli.ready()
--- @param on_complete function Callback function
--- @return string Operation ID
function M.ready(on_complete)
  return M.run("ready", cli.ready, {}, on_complete)
end

--- Async wrapper for cli.show()
--- @param id string Task ID
--- @param on_complete function Callback function
--- @return string Operation ID
function M.show(id, on_complete)
  return M.run("show", cli.show, { id }, on_complete)
end

--- Async wrapper for cli.create()
--- @param title string Task title
--- @param on_complete function Callback function
--- @return string Operation ID
function M.create(title, on_complete)
  return M.run("create", cli.create, { title }, on_complete)
end

--- Async wrapper for cli.update()
--- @param id string Task ID
--- @param opts table Update options
--- @param on_complete function Callback function
--- @return string Operation ID
function M.update(id, opts, on_complete)
  return M.run("update", cli.update, { id, opts }, on_complete)
end

--- Async wrapper for cli.close()
--- @param id string Task ID
--- @param on_complete function Callback function
--- @return string Operation ID
function M.close(id, on_complete)
  return M.run("close", cli.close, { id }, on_complete)
end

--- Async wrapper for cli.sync()
--- @param on_complete function Callback function
--- @return string Operation ID
function M.sync(on_complete)
  return M.run("sync", cli.sync, {}, on_complete)
end

--- Queue an operation for later execution
--- @param name string Operation name
--- @param fn function Function to execute
--- @param args table Arguments
--- @param on_complete function Completion callback
--- @return string Operation ID
function M.queue(name, fn, args, on_complete)
  local op_id = create_operation_id()

  -- Create progress tracker for queued operation
  progress.create_operation(op_id, name)

  local queued_op = {
    id = op_id,
    name = name,
    fn = fn,
    args = args,
    on_complete = on_complete,
  }

  table.insert(operations.queue, queued_op)

  -- Process queue if enabled
  if config.queue_enabled then
    M.process_queue()
  end

  return op_id
end

--- Process operation queue
function M.process_queue()
  if not config.queue_enabled or #operations.queue == 0 then
    return
  end

  -- Count current active operations
  local active_count = 0
  for _ in pairs(operations.active) do
    active_count = active_count + 1
  end

  -- Execute queued operations if below max concurrent
  while active_count < config.max_concurrent and #operations.queue > 0 do
    local queued = table.remove(operations.queue, 1)
    if queued then
      M.run(queued.name, queued.fn, queued.args, queued.on_complete)
      active_count = active_count + 1
    end
  end
end

--- Get queued operations
--- @return table List of queued operation info
function M.get_queued()
  local queued = {}
  for _, op in ipairs(operations.queue) do
    local progress_info = progress.get_operation(op.id)
    table.insert(queued, {
      id = op.id,
      name = op.name,
      status = "queued",
      progress = progress_info,
    })
  end
  return queued
end

--- Set maximum concurrent operations
--- @param max integer Maximum number of concurrent operations
function M.set_max_concurrent(max)
  config.max_concurrent = max
  M.process_queue()
end

--- Enable/disable operation queuing
--- @param enabled boolean Enable or disable queuing
function M.set_queue_enabled(enabled)
  config.queue_enabled = enabled
  if enabled then
    M.process_queue()
  end
end

--- Get number of queued operations
--- @return integer Number of operations in queue
function M.get_queue_size()
  return #operations.queue
end

--- Set default timeout for operations
--- @param timeout integer Timeout in milliseconds
function M.set_default_timeout(timeout)
  config.default_timeout = timeout
end

--- Enable/disable automatic retry on failure
--- @param enabled boolean Enable or disable retry
function M.set_retry_enabled(enabled)
  config.retry_enabled = enabled
end

--- Set maximum retry attempts
--- @param max integer Maximum attempts
function M.set_retry_max_attempts(max)
  config.retry_max_attempts = max
end

--- Enable/disable completion notifications
--- @param enabled boolean Enable or disable
function M.set_notify_on_complete(enabled)
  config.notify_on_complete = enabled
end

--- Enable/disable error notifications
--- @param enabled boolean Enable or disable
function M.set_notify_on_error(enabled)
  config.notify_on_error = enabled
end

--- Send notification for operation result
--- @param operation table Operation object
local function notify_result(operation)
  if operation.status == "completed" and config.notify_on_complete then
    local elapsed = M.get_elapsed(operation.id)
    local time_str = ""
    if elapsed > 1000 then
      time_str = " (" .. math.floor(elapsed / 1000) .. "s)"
    elseif elapsed > 0 then
      time_str = " (" .. elapsed .. "ms)"
    end
    vim.notify(operation.name .. " completed successfully" .. time_str, vim.log.levels.INFO)
  elseif operation.status == "failed" and config.notify_on_error then
    local msg = operation.name .. " failed"
    if operation.result then
      msg = msg .. ": " .. tostring(operation.result)
    end
    vim.notify(msg, vim.log.levels.ERROR)
  end
end

--- Retry an operation
--- @param op_id string Original operation ID
--- @return string New operation ID
function M.retry(op_id)
  local op = operations.completed[op_id] or operations.failed[op_id]
  if not op then
    return nil
  end

  -- Increment retry count
  op.retry_count = (op.retry_count or 0) + 1

  if op.retry_count > config.retry_max_attempts then
    vim.notify("Max retry attempts exceeded for " .. op.name, vim.log.levels.WARN)
    -- Update progress tracker to reflect failure
    local progress_info = progress.get_operation(op_id)
    if progress_info then
      progress.fail_operation(op_id, "Max retry attempts exceeded")
    end
    return nil
  end

  -- Run the operation again
  return M.run(op.name, op.fn, op.args, op.on_complete)
end

--- Get configuration
--- @return table Current configuration
function M.get_config()
  return vim.deepcopy(config)
end

--- Set configuration
--- @param new_config table Configuration updates
function M.set_config(new_config)
  config = vim.tbl_extend("force", config, new_config)
end

--- Get unified operation info combining async and progress tracking
--- @param op_id string Operation ID
--- @return table Unified operation info
function M.get_operation(op_id)
  local op = operations.active[op_id] or operations.completed[op_id] or operations.failed[op_id]
  if not op then
    -- Try to get from progress tracking if not in operations
    local progress_info = progress.get_operation(op_id)
    if progress_info then
      return {
        id = op_id,
        status = progress_info.status,
        name = progress_info.title,
        elapsed = progress_info.elapsed,
        success = progress_info and progress.is_operation_success(op_id) or nil,
        result = progress.get_operation_result(op_id),
      }
    end
    return nil
  end

  -- Combine async operation info with progress info
  local progress_info = progress.get_operation(op_id)
  return {
    id = op.id,
    name = op.name,
    status = op.status,
    start_time = op.start_time,
    end_time = op.end_time,
    success = op.success,
    result = op.result,
    elapsed = progress_info and progress_info.elapsed or M.get_elapsed(op_id),
    retry_count = op.retry_count or 0,
  }
end

return M
