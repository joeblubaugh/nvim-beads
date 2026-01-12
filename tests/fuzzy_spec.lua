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

-- Tests for beads fuzzy finder module

describe("beads.fuzzy", function()
  local fuzzy = require("beads.fuzzy")

  describe("initialization", function()
    it("should initialize with builtin finder always available", function()
      fuzzy.init()
      local available = fuzzy.get_available_finders()
      assert.truthy(vim.tbl_contains(available, "builtin"))
    end)

    it("should have a current finder set", function()
      fuzzy.init()
      assert.truthy(fuzzy.get_finder())
    end)

    it("should be available after init", function()
      fuzzy.init()
      assert.is_true(fuzzy.is_available())
    end)
  end)

  describe("finder backend switching", function()
    it("should allow switching to builtin", function()
      fuzzy.init()
      fuzzy.set_finder("builtin")
      assert.equals("builtin", fuzzy.get_finder())
    end)

    it("should only switch to available finders", function()
      fuzzy.init()
      local current = fuzzy.get_finder()
      fuzzy.set_finder("nonexistent_finder")
      -- Should still be the same after failed attempt
      assert.equals(current, fuzzy.get_finder())
    end)
  end)

  describe("available finders", function()
    it("should return list of available finders", function()
      fuzzy.init()
      local available = fuzzy.get_available_finders()
      assert.truthy(type(available) == "table")
      assert.truthy(#available > 0)
    end)

    it("should always include builtin", function()
      fuzzy.init()
      local available = fuzzy.get_available_finders()
      assert.truthy(vim.tbl_contains(available, "builtin"))
    end)
  end)
end)

describe("beads.fuzzy_builtin", function()
  local builtin = require("beads.fuzzy_builtin")

  describe("find_task", function()
    it("should format task entries correctly", function()
      local task = {
        id = "test-123",
        title = "Test Task",
        priority = "P1",
        status = "open"
      }
      local tasks = { task }

      -- Mock vim.ui.select
      local selected_task = nil
      vim.ui.select = function(items, opts, callback)
        callback(items[1])
      end

      builtin.find_task(tasks, function(selected)
        selected_task = selected
      end)

      assert.equals("test-123", selected_task.id)
    end)

    it("should handle tasks with default values", function()
      local task = {
        id = "test-456"
        -- Missing title, priority, status
      }
      local tasks = { task }

      vim.ui.select = function(items, opts, callback)
        callback(items[1])
      end

      builtin.find_task(tasks, function(selected)
        -- Should not error on missing fields
        assert.equals("test-456", selected.id)
      end)
    end)
  end)

  describe("find_status", function()
    it("should provide all status options", function()
      local task = { id = "test-123", status = "open" }
      local provided_items = nil

      vim.ui.select = function(items, opts, callback)
        provided_items = items
      end

      builtin.find_status(task, function() end)

      assert.equals(3, #provided_items)
      assert.truthy(vim.tbl_contains(provided_items, "open"))
      assert.truthy(vim.tbl_contains(provided_items, "in_progress"))
      assert.truthy(vim.tbl_contains(provided_items, "closed"))
    end)

    it("should call callback with selected status", function()
      local task = { id = "test-123", status = "open" }
      local selected_status = nil

      vim.ui.select = function(items, opts, callback)
        callback("in_progress")
      end

      builtin.find_status(task, function(status)
        selected_status = status
      end)

      assert.equals("in_progress", selected_status)
    end)
  end)

  describe("find_priority", function()
    it("should provide all priority options", function()
      local task = { id = "test-123", priority = "P2" }
      local provided_items = nil

      vim.ui.select = function(items, opts, callback)
        provided_items = items
      end

      builtin.find_priority(task, function() end)

      assert.equals(3, #provided_items)
      assert.truthy(vim.tbl_contains(provided_items, "P1"))
      assert.truthy(vim.tbl_contains(provided_items, "P2"))
      assert.truthy(vim.tbl_contains(provided_items, "P3"))
    end)

    it("should call callback with selected priority", function()
      local task = { id = "test-123", priority = "P2" }
      local selected_priority = nil

      vim.ui.select = function(items, opts, callback)
        callback("P1")
      end

      builtin.find_priority(task, function(priority)
        selected_priority = priority
      end)

      assert.equals("P1", selected_priority)
    end)
  end)
end)
