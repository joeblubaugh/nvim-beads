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

-- Tests for beads filters module

describe("beads.filters", function()
  local filters = require("beads.filters")

  describe("apply_filters", function()
    local task1 = { id = "1", title = "Task 1", priority = "P1", status = "open", assignee = "alice" }
    local task2 = { id = "2", title = "Task 2", priority = "P2", status = "in_progress", assignee = "bob" }
    local task3 = { id = "3", title = "Task 3", priority = "P1", status = "closed", assignee = "alice" }
    local tasks = { task1, task2, task3 }

    it("should return all tasks when no filters applied", function()
      local filter_state = { priority = {}, status = {}, assignee = {} }
      local result = filters.apply_filters(tasks, filter_state)
      assert.equals(3, #result)
    end)

    it("should filter by priority", function()
      local filter_state = { priority = { "P1" }, status = {}, assignee = {} }
      local result = filters.apply_filters(tasks, filter_state)
      assert.equals(2, #result)
      assert.equals("1", result[1].id)
      assert.equals("3", result[2].id)
    end)

    it("should filter by status", function()
      local filter_state = { priority = {}, status = { "open" }, assignee = {} }
      local result = filters.apply_filters(tasks, filter_state)
      assert.equals(1, #result)
      assert.equals("1", result[1].id)
    end)

    it("should support multiple filters with AND logic", function()
      local filter_state = { priority = { "P1" }, status = { "open" }, assignee = {} }
      local result = filters.apply_filters(tasks, filter_state)
      assert.equals(1, #result)
      assert.equals("1", result[1].id)
    end)

    it("should support multiple values in a filter (OR within filter type)", function()
      local filter_state = { priority = { "P1", "P2" }, status = {}, assignee = {} }
      local result = filters.apply_filters(tasks, filter_state)
      assert.equals(3, #result)
    end)
  end)

  describe("has_active_filters", function()
    it("should return false when no filters set", function()
      local filter_state = { priority = {}, status = {}, assignee = {} }
      assert.is_false(filters.has_active_filters(filter_state))
    end)

    it("should return true when priority filter set", function()
      local filter_state = { priority = { "P1" }, status = {}, assignee = {} }
      assert.is_true(filters.has_active_filters(filter_state))
    end)

    it("should return true when any filter set", function()
      local filter_state = { priority = {}, status = { "open" }, assignee = {} }
      assert.is_true(filters.has_active_filters(filter_state))
    end)
  end)

  describe("get_filter_description", function()
    it("should return 'No filters active' when empty", function()
      local filter_state = { priority = {}, status = {}, assignee = {} }
      local desc = filters.get_filter_description(filter_state)
      assert.equals("No filters active", desc)
    end)

    it("should describe priority filters", function()
      local filter_state = { priority = { "P1", "P2" }, status = {}, assignee = {} }
      local desc = filters.get_filter_description(filter_state)
      assert.matches("Priority: P1, P2", desc)
    end)

    it("should combine multiple filter descriptions", function()
      local filter_state = { priority = { "P1" }, status = { "open" }, assignee = { "alice" } }
      local desc = filters.get_filter_description(filter_state)
      assert.matches("Priority:", desc)
      assert.matches("Status:", desc)
      assert.matches("Assignee:", desc)
    end)
  end)
end)
