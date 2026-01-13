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

-- Progress tracking and indicators for beads operations

local M = {}

-- Progress trackers
local trackers = {}

--- Create a new progress tracker
--- @param id string Unique identifier
--- @param total integer Total items to process (optional)
--- @param title string Progress title/description
--- @return table Progress tracker object
function M.new(id, total, title)
  total = total or 0
  title = title or id

  local tracker = {
    id = id,
    title = title,
    total = total,
    current = 0,
    status = "running",
    start_time = vim.fn.reltime(),
    messages = {},
  }

  trackers[id] = tracker
  return tracker
end

--- Update progress
--- @param id string Tracker ID
--- @param current integer Current progress (0 to total)
--- @param message string Optional status message
function M.update(id, current, message)
  local tracker = trackers[id]
  if not tracker then
    return
  end

  tracker.current = math.min(current, tracker.total)

  if message then
    table.insert(tracker.messages, {
      time = vim.fn.reltime(),
      text = message,
    })
  end
end

--- Increment progress
--- @param id string Tracker ID
--- @param increment integer Amount to increment (default 1)
--- @param message string Optional status message
function M.increment(id, increment, message)
  local tracker = trackers[id]
  if not tracker then
    return
  end

  increment = increment or 1
  tracker.current = math.min(tracker.current + increment, tracker.total)

  if message then
    table.insert(tracker.messages, {
      time = vim.fn.reltime(),
      text = message,
    })
  end
end

--- Mark progress as complete
--- @param id string Tracker ID
--- @param message string Optional completion message
function M.complete(id, message)
  local tracker = trackers[id]
  if not tracker then
    return
  end

  tracker.status = "completed"
  tracker.current = tracker.total
  tracker.end_time = vim.fn.reltime()

  if message then
    table.insert(tracker.messages, {
      time = vim.fn.reltime(),
      text = message,
    })
  end
end

--- Mark progress as failed
--- @param id string Tracker ID
--- @param error string Error message
function M.fail(id, error)
  local tracker = trackers[id]
  if not tracker then
    return
  end

  tracker.status = "failed"
  tracker.end_time = vim.fn.reltime()
  tracker.error = error

  table.insert(tracker.messages, {
    time = vim.fn.reltime(),
    text = "Error: " .. error,
  })
end

--- Get progress percentage
--- @param id string Tracker ID
--- @return integer Percentage (0-100)
function M.get_percentage(id)
  local tracker = trackers[id]
  if not tracker or tracker.total == 0 then
    return 0
  end

  return math.floor((tracker.current / tracker.total) * 100)
end

--- Get progress bar string
--- @param id string Tracker ID
--- @param width integer Bar width (default 20)
--- @return string Progress bar representation
function M.get_bar(id, width)
  width = width or 20
  local tracker = trackers[id]
  if not tracker or tracker.total == 0 then
    return string.rep("░", width)
  end

  local filled = math.floor((tracker.current / tracker.total) * width)
  local empty = width - filled

  return string.rep("█", filled) .. string.rep("░", empty)
end

--- Get progress info
--- @param id string Tracker ID
--- @return table Progress information
function M.get_info(id)
  local tracker = trackers[id]
  if not tracker then
    return nil
  end

  local elapsed = 0
  local end_time = tracker.end_time or vim.fn.reltime()
  elapsed = math.floor(vim.fn.reltimeMs(vim.fn.reltime(tracker.start_time, end_time)))

  local rate = 0
  if elapsed > 0 then
    rate = (tracker.current / (elapsed / 1000))
  end

  local eta = 0
  if rate > 0 and tracker.current < tracker.total then
    eta = math.floor((tracker.total - tracker.current) / rate)
  end

  return {
    id = tracker.id,
    title = tracker.title,
    current = tracker.current,
    total = tracker.total,
    percentage = M.get_percentage(id),
    status = tracker.status,
    elapsed = elapsed,
    rate = rate,
    eta = eta,
    error = tracker.error,
    message_count = #tracker.messages,
  }
end

--- Get formatted progress display
--- @param id string Tracker ID
--- @return string Formatted progress string
function M.get_display(id)
  local info = M.get_info(id)
  if not info then
    return ""
  end

  local bar = M.get_bar(id, 15)
  local pct = info.percentage
  local current = info.current
  local total = info.total

  if total > 0 then
    return string.format("%s %3d%% [%d/%d] %s", bar, pct, current, total, info.title)
  else
    return string.format("%s %s", bar, info.title)
  end
end

--- Get elapsed time
--- @param id string Tracker ID
--- @return integer Milliseconds elapsed
function M.get_elapsed(id)
  local tracker = trackers[id]
  if not tracker then
    return 0
  end

  local end_time = tracker.end_time or vim.fn.reltime()
  return math.floor(vim.fn.reltimeMs(vim.fn.reltime(tracker.start_time, end_time)))
end

--- Get all active trackers
--- @return table List of active tracker IDs
function M.get_active()
  local active = {}
  for id, tracker in pairs(trackers) do
    if tracker.status == "running" then
      table.insert(active, id)
    end
  end
  return active
end

--- Get tracker by ID
--- @param id string Tracker ID
--- @return table Tracker object
function M.get_tracker(id)
  return trackers[id]
end

--- Clear completed tracker
--- @param id string Tracker ID
function M.clear(id)
  trackers[id] = nil
end

--- Clear all completed trackers
function M.clear_completed()
  for id, tracker in pairs(trackers) do
    if tracker.status ~= "running" then
      trackers[id] = nil
    end
  end
end

--- Get summary of all trackers
--- @return table Summary statistics
function M.get_summary()
  local running = 0
  local completed = 0
  local failed = 0

  for _, tracker in pairs(trackers) do
    if tracker.status == "running" then
      running = running + 1
    elseif tracker.status == "completed" then
      completed = completed + 1
    elseif tracker.status == "failed" then
      failed = failed + 1
    end
  end

  return {
    running = running,
    completed = completed,
    failed = failed,
    total = running + completed + failed,
  }
end

--- Create operation tracker (convenience for async operations)
--- @param op_id string Operation ID
--- @param name string Operation name
--- @return table Progress tracker object
function M.create_operation(op_id, name)
  return M.new(op_id, 1, name)
end

--- Mark operation as succeeded
--- @param op_id string Operation ID
--- @param result any Operation result
function M.succeed_operation(op_id, result)
  local tracker = trackers[op_id]
  if tracker then
    tracker.result = result
    tracker.success = true
    M.complete(op_id, "completed")
  end
end

--- Mark operation as failed
--- @param op_id string Operation ID
--- @param error any Error result
function M.fail_operation(op_id, error)
  local tracker = trackers[op_id]
  if tracker then
    tracker.result = error
    tracker.success = false
    M.fail(op_id, tostring(error))
  end
end

--- Get operation result
--- @param op_id string Operation ID
--- @return any Result value
function M.get_operation_result(op_id)
  local tracker = trackers[op_id]
  return tracker and tracker.result or nil
end

--- Check if operation succeeded
--- @param op_id string Operation ID
--- @return boolean Success status
function M.is_operation_success(op_id)
  local tracker = trackers[op_id]
  return tracker and tracker.success or false
end

--- Get tracker by ID (alias for consistency)
--- @param op_id string Operation ID
--- @return table Tracker info
function M.get_operation(op_id)
  return M.get_info(op_id)
end

return M
