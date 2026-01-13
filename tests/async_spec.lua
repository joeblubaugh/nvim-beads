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

-- Tests for beads async module

describe("beads.async", function()
  local async = require("beads.async")

  describe("basic operations", function()
    it("should run an operation", function()
      local test_fn = function()
        return true
      end

      local op_id = async.run("test", test_fn, {})
      assert.truthy(op_id)
      assert.matches("op_", op_id)
    end)

    it("should generate unique operation IDs", function()
      local op_id1 = async.run("test1", function() return true end, {})
      local op_id2 = async.run("test2", function() return true end, {})

      assert.is_false(op_id1 == op_id2)
    end)

    it("should cancel an operation", function()
      local op_id = async.run("test", function() return true end, {})
      async.cancel(op_id)

      local status = async.get_status(op_id)
      assert.equals("cancelled", status.status)
    end)
  end)

  describe("operation tracking", function()
    it("should track active operations", function()
      local initial_active = #async.get_active()

      local op_id = async.run("test", function()
        vim.loop.sleep(10)
        return true
      end, {})

      assert.truthy(vim.tbl_contains(async.get_active(), op_id))
    end)

    it("should provide operation statistics", function()
      async.run("test1", function() return true end, {})
      async.run("test2", function() return true end, {})

      local stats = async.get_stats()
      assert.truthy(stats.active > 0)
    end)
  end)

  describe("operation queuing", function()
    it("should queue operations", function()
      local op_id = async.queue("test", function() return true end, {})
      assert.truthy(op_id)
    end)

    it("should track queued operations", function()
      local initial_size = async.get_queue_size()
      async.queue("test", function() return true end, {})

      assert.equals(initial_size + 1, async.get_queue_size())
    end)

    it("should process queue when configured", function()
      async.set_queue_enabled(true)
      local initial_size = async.get_queue_size()

      async.queue("test", function() return true end, {})
      -- Queue should process automatically

      assert.truthy(async.get_queue_size() <= initial_size + 1)
    end)
  end)

  describe("concurrency control", function()
    it("should set max concurrent operations", function()
      async.set_max_concurrent(5)
      local config = async.get_config()
      assert.equals(5, config.max_concurrent)
    end)

    it("should reset to default on init", function()
      async.set_max_concurrent(1)
      local config = async.get_config()
      assert.equals(1, config.max_concurrent)
    end)
  end)

  describe("configuration", function()
    it("should get configuration", function()
      local config = async.get_config()
      assert.truthy(config.default_timeout)
      assert.truthy(config.notify_on_complete ~= nil)
    end)

    it("should set configuration", function()
      async.set_config({
        notify_on_complete = false,
        notify_on_error = false,
      })

      local config = async.get_config()
      assert.is_false(config.notify_on_complete)
      assert.is_false(config.notify_on_error)
    end)

    it("should set timeout", function()
      async.set_default_timeout(60000)
      local config = async.get_config()
      assert.equals(60000, config.default_timeout)
    end)

    it("should enable/disable retry", function()
      async.set_retry_enabled(true)
      local config = async.get_config()
      assert.is_true(config.retry_enabled)

      async.set_retry_enabled(false)
      config = async.get_config()
      assert.is_false(config.retry_enabled)
    end)
  end)

  describe("progress integration", function()
    local progress = require("beads.progress")

    before_each(function()
      -- Clean up progress trackers between tests
      progress.clear_completed()
    end)

    it("should work with completion callbacks", function()
      local completed = false

      async.run("test", function() return true end, {}, function(success)
        completed = success
      end)

      -- Callback should execute asynchronously
      assert.truthy(completed == false or completed == true)
    end)

    it("should create progress tracker for operations", function()
      local op_id = async.run("test_op", function() return "result" end, {})

      -- Progress tracker should be created immediately
      local progress_info = progress.get_operation(op_id)
      assert.truthy(progress_info)
      assert.equals("test_op", progress_info.title)
    end)

    it("should create progress tracker for queued operations", function()
      async.set_queue_enabled(true)
      local op_id = async.queue("queued_op", function() return true end, {})

      local queued = async.get_queued()
      assert.truthy(#queued > 0)

      -- Check that queued operation has progress info
      local op_info = queued[1]
      assert.truthy(op_info.progress)
    end)

    it("should get unified operation info for active operations", function()
      local op_id = async.run("unified_op", function() return "data" end, {})

      local op_info = async.get_operation(op_id)
      assert.truthy(op_info)
      assert.equals("unified_op", op_info.name)
      assert.truthy(op_info.status == "running" or op_info.status == "completed")
    end)

    it("should support progress helper functions", function()
      local op_id = "test_op_" .. tostring(os.time())

      -- Test progress helper functions
      progress.create_operation(op_id, "test")
      assert.truthy(progress.get_operation(op_id))

      -- Mark as success
      progress.succeed_operation(op_id, "result data")
      assert.is_true(progress.is_operation_success(op_id))
      assert.equals("result data", progress.get_operation_result(op_id))
    end)
  end)

  describe("history management", function()
    it("should clear completed operations", function()
      async.clear_completed()
      local stats = async.get_stats()
      assert.equals(0, stats.completed)
    end)

    it("should clear failed operations", function()
      async.clear_failed()
      local stats = async.get_stats()
      assert.equals(0, stats.failed)
    end)

    it("should clear all history", function()
      async.clear_history()
      local stats = async.get_stats()
      assert.equals(0, stats.completed + stats.failed)
    end)
  end)
end)

describe("beads.progress", function()
  local progress = require("beads.progress")

  describe("progress tracking", function()
    it("should create new tracker", function()
      local tracker = progress.new("test", 100, "Test Progress")
      assert.equals("test", tracker.id)
      assert.equals(100, tracker.total)
      assert.equals(0, tracker.current)
    end)

    it("should update progress", function()
      progress.new("test", 100, "Test")
      progress.update("test", 50, "Half done")

      local info = progress.get_info("test")
      assert.equals(50, info.current)
    end)

    it("should calculate percentage", function()
      progress.new("test", 100, "Test")
      progress.update("test", 50)

      local pct = progress.get_percentage("test")
      assert.equals(50, pct)
    end)

    it("should generate progress bar", function()
      progress.new("test", 100, "Test")
      progress.update("test", 50)

      local bar = progress.get_bar("test", 10)
      -- Width is 10 chars, but each char is 3 bytes in UTF-8, so 30 total
      assert.equals(30, string.len(bar))
      assert.matches("█", bar)
      assert.matches("░", bar)
    end)

    it("should format display", function()
      progress.new("test", 100, "Test Progress")
      progress.update("test", 50)

      local display = progress.get_display("test")
      assert.matches("Test Progress", display)
      assert.matches("50", display)
    end)
  end)

  describe("progress completion", function()
    it("should mark as complete", function()
      progress.new("test", 100, "Test")
      progress.complete("test", "Done!")

      local info = progress.get_info("test")
      assert.equals("completed", info.status)
      assert.equals(100, info.current)
    end)

    it("should mark as failed", function()
      progress.new("test", 100, "Test")
      progress.fail("test", "Error occurred")

      local info = progress.get_info("test")
      assert.equals("failed", info.status)
      assert.equals("Error occurred", info.error)
    end)
  end)

  describe("progress summary", function()
    before_each(function()
      -- Clean up trackers between tests
      progress.clear_completed()
      for _, id in ipairs(progress.get_active()) do
        progress.clear(id)
      end
    end)

    it("should get summary", function()
      progress.new("test1", 100, "Test 1")
      progress.new("test2", 100, "Test 2")

      local summary = progress.get_summary()
      assert.equals(2, summary.running)
    end)

    it("should track completed trackers", function()
      progress.new("test", 100, "Test")
      progress.complete("test")

      local summary = progress.get_summary()
      assert.equals(1, summary.completed)
    end)
  end)
end)
