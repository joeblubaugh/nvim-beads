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

-- Active operations tracking
local operations = {
  active = {},
  completed = {},
  failed = {},
}

-- Operation counter for unique IDs
local operation_counter = 0

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

  local operation = {
    id = op_id,
    name = name,
    status = "running",
    start_time = vim.fn.reltime(),
    on_complete = on_complete,
  }

  operations.active[op_id] = operation

  -- Run in a timer to avoid blocking
  vim.loop.new_timer():start(0, 0, function()
    vim.schedule(function()
      local success, result = pcall(fn, unpack(args))

      operation.status = success and "completed" or "failed"
      operation.end_time = vim.fn.reltime()
      operation.result = result
      operation.success = success

      -- Move to completed/failed
      operations.active[op_id] = nil
      if success then
        operations.completed[op_id] = operation
      else
        operations.failed[op_id] = operation
      end

      -- Call completion callback
      if operation.on_complete then
        operation.on_complete(success, result)
      end
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

  return {
    id = op.id,
    name = op.name,
    status = op.status,
    start_time = op.start_time,
    end_time = op.end_time,
    success = op.success,
    result = op.result,
  }
end

--- Get elapsed time for operation
--- @param op_id string Operation ID
--- @return integer Elapsed time in milliseconds
function M.get_elapsed(op_id)
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
  for op_id, _ in pairs(operations.active) do
    table.insert(active, op_id)
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
  operations.completed = {}
end

--- Clear failed operations
function M.clear_failed()
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
  local total_active = 0
  local total_completed = 0
  local total_failed = 0

  for _ in pairs(operations.active) do
    total_active = total_active + 1
  end

  for _ in pairs(operations.completed) do
    total_completed = total_completed + 1
  end

  for _ in pairs(operations.failed) do
    total_failed = total_failed + 1
  end

  return {
    active = total_active,
    completed = total_completed,
    failed = total_failed,
    total = total_active + total_completed + total_failed,
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

return M
