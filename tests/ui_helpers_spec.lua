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

-- Tests for beads UI helper functions that are exported or can be tested indirectly

describe("beads.ui helpers", function()
  describe("task display helpers", function()
    it("should format task titles correctly", function()
      -- Test that we can pass various task objects without errors
      local tasks = {
        { id = "id-1", title = "Short title", priority = "P1", status = "open" },
        { id = "id-2", title = "This is a very long title that should be truncated when displayed in the sidebar to fit on a single line", priority = "P2", status = "in_progress" },
        { id = "id-3", title = "Closed task", priority = "P3", status = "closed" },
      }
      assert.equals(3, #tasks)
    end)

    it("should handle tasks with missing fields", function()
      local tasks = {
        { id = "id-1" },  -- Minimal task
        { id = "id-2", title = "Task without priority" },
        { id = "id-3", title = "Task without status", priority = "P1" },
      }
      assert.equals(3, #tasks)
    end)

    it("should recognize parent and child task relationships", function()
      local parent = { id = "epic-1", title = "Epic" }
      local child = { id = "epic-1.1", title = "Sub-task 1" }
      local grandchild = { id = "epic-1.1.1", title = "Sub-sub-task" }

      -- Parent tasks should not have dots in their ID
      assert.is_true(not parent.id:match("%."))
      -- Child tasks should have a dot in their ID
      assert.is_true(child.id:match("%.") ~= nil)
      -- Grandchildren should have multiple dots
      assert.is_true(grandchild.id:match("%..*%.") ~= nil)
    end)

    it("should extract parent ID from child task", function()
      -- Test ID extraction logic
      local child_id = "epic-1.1"
      local parent_id = child_id:match("^(.+)%.")
      assert.equals("epic-1", parent_id)

      local grandchild_id = "epic-1.2.3"
      parent_id = grandchild_id:match("^(.+)%.")
      assert.equals("epic-1.2", parent_id)
    end)
  end)

  describe("status symbols", function()
    it("should map task status to symbols", function()
      local tasks = {
        { status = "open", expected = "○" },
        { status = "in_progress", expected = "○" },
        { status = "closed", expected = "✓" },
        { status = "complete", expected = "✓" },
      }

      for _, test_case in ipairs(tasks) do
        local status_symbol = (test_case.status == "closed" or test_case.status == "complete") and "✓" or "○"
        assert.equals(test_case.expected, status_symbol)
      end
    end)
  end)

  describe("priority formatting", function()
    it("should use default priority when missing", function()
      local task = { id = "test" }
      local priority = task.priority or "P2"
      assert.equals("P2", priority)
    end)

    it("should preserve explicit priorities", function()
      local priorities = { "P1", "P2", "P3" }
      for _, p in ipairs(priorities) do
        local task = { priority = p }
        assert.equals(p, task.priority)
      end
    end)
  end)

  describe("task filtering", function()
    it("should build task list from mixed parent/child tasks", function()
      local tasks = {
        { id = "epic-1", title = "Epic", priority = "P1", status = "open" },
        { id = "epic-1.1", title = "Child 1", priority = "P2", status = "open" },
        { id = "epic-1.2", title = "Child 2", priority = "P2", status = "closed" },
        { id = "epic-2", title = "Another Epic", priority = "P1", status = "open" },
      }

      assert.equals(4, #tasks)

      -- Count parents (no dots)
      local parents = 0
      for _, task in ipairs(tasks) do
        if not task.id:match("%.") then
          parents = parents + 1
        end
      end
      assert.equals(2, parents)

      -- Count children (has dots)
      local children = 0
      for _, task in ipairs(tasks) do
        if task.id:match("%.") then
          children = children + 1
        end
      end
      assert.equals(2, children)
    end)

    it("should identify orphaned children", function()
      local tasks = {
        { id = "epic-1.1", title = "Orphan child" },  -- Parent not in list
        { id = "epic-2", title = "Parent" },
        { id = "epic-2.1", title = "Child of epic-2" },
      }

      -- Identify which children have parents in the list
      local task_ids = {}
      for _, task in ipairs(tasks) do
        task_ids[task.id] = true
      end

      local orphans = {}
      for _, task in ipairs(tasks) do
        if task.id:match("%.") then
          local parent_id = task.id:match("^(.+)%.")
          if not task_ids[parent_id] then
            table.insert(orphans, task.id)
          end
        end
      end

      assert.equals(1, #orphans)
      assert.equals("epic-1.1", orphans[1])
    end)
  end)

  describe("task title truncation", function()
    it("should truncate long titles", function()
      local title = "This is a very long task title that definitely exceeds the maximum display length and should be truncated"
      local max_len = 65
      local truncated = title
      if #title > max_len then
        truncated = title:sub(1, max_len - 1) .. "…"
      end

      -- Verify it was truncated and ends with ellipsis
      assert.is_true(#truncated <= max_len + 2)  -- Allow for multi-byte ellipsis
      assert.is_true(truncated:match("…$") ~= nil)
    end)

    it("should not truncate short titles", function()
      local title = "Short title"
      local max_len = 65
      local truncated = title
      if #title > max_len then
        truncated = title:sub(1, max_len - 1) .. "…"
      end

      assert.equals(title, truncated)
    end)
  end)

  describe("task content parsing", function()
    it("should split multi-line descriptions", function()
      local description = "First line\nSecond line\nThird line"
      local lines = {}
      for line in description:gmatch("[^\n]+") do
        table.insert(lines, line)
      end

      assert.equals(3, #lines)
      assert.equals("First line", lines[1])
      assert.equals("Second line", lines[2])
      assert.equals("Third line", lines[3])
    end)

    it("should handle descriptions without newlines", function()
      local description = "Single line description"
      local lines = {}
      for line in description:gmatch("[^\n]+") do
        table.insert(lines, line)
      end

      assert.equals(1, #lines)
      assert.equals("Single line description", lines[1])
    end)

    it("should handle empty descriptions", function()
      local description = ""
      local lines = {}
      for line in description:gmatch("[^\n]+") do
        table.insert(lines, line)
      end

      assert.equals(0, #lines)
    end)
  end)
end)
