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

-- Cache and debouncing utilities for Beads plugin

local M = {}

-- Debounce state storage
local debounce_timers = {}

-- Default debounce delay (milliseconds)
local DEFAULT_DEBOUNCE_DELAY = 300

--- Create a debounced function
--- @param func function Function to debounce
--- @param delay number|nil Delay in milliseconds (default: 300ms)
--- @return function Debounced function
function M.debounce(func, delay)
  delay = delay or DEFAULT_DEBOUNCE_DELAY
  local timer = nil

  return function(...)
    local args = { ... }

    if timer then
      timer:stop()
      timer:close()
    end

    timer = vim.loop.new_timer()
    timer:start(
      delay,
      0,
      vim.schedule_wrap(function()
        func(unpack(args))
        timer:close()
        timer = nil
      end)
    )
  end
end

--- Create a throttled function
--- @param func function Function to throttle
--- @param delay number|nil Delay in milliseconds (default: 300ms)
--- @return function Throttled function
function M.throttle(func, delay)
  delay = delay or DEFAULT_DEBOUNCE_DELAY
  local last_called = 0

  return function(...)
    local now = vim.loop.now()
    if now - last_called >= delay then
      last_called = now
      func(...)
    end
  end
end

--- Register a debounced command
--- @param name string Command name or unique identifier
--- @param func function Function to debounce
--- @param delay number|nil Delay in milliseconds
function M.register_debounced(name, func, delay)
  -- Clean up old timer if exists
  if debounce_timers[name] then
    debounce_timers[name]:stop()
    debounce_timers[name]:close()
  end

  delay = delay or DEFAULT_DEBOUNCE_DELAY

  -- Return a function that handles debouncing
  return function(...)
    local args = { ... }

    if debounce_timers[name] then
      debounce_timers[name]:stop()
      debounce_timers[name]:close()
    end

    debounce_timers[name] = vim.loop.new_timer()
    debounce_timers[name]:start(
      delay,
      0,
      vim.schedule_wrap(function()
        func(unpack(args))
        if debounce_timers[name] then
          debounce_timers[name]:close()
          debounce_timers[name] = nil
        end
      end)
    )
  end
end

--- Cancel a pending debounced operation
--- @param name string Command name or unique identifier
function M.cancel_debounced(name)
  if debounce_timers[name] then
    debounce_timers[name]:stop()
    debounce_timers[name]:close()
    debounce_timers[name] = nil
  end
end

--- Flush all pending debounced operations
function M.flush_all()
  for name, timer in pairs(debounce_timers) do
    if timer then
      timer:stop()
      timer:close()
      debounce_timers[name] = nil
    end
  end
end

return M
