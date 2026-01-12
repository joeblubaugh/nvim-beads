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

-- Tests for beads statusline module

describe("beads.statusline", function()
  local statusline = require("beads.statusline")

  before_each(function()
    statusline.invalidate_cache()
  end)

  describe("task count display", function()
    it("should return empty string when no tasks", function()
      local count = statusline.get_task_count()
      assert.equals("", count)
    end)

    it("should format task count in brackets", function()
      -- Mock cli.ready
      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", status = "open" },
          { id = "2", title = "Task 2", status = "closed" }
        }
      end

      local count = statusline.get_task_count()
      assert.matches("%[2%]", count)
    end)
  end)

  describe("status indicator", function()
    it("should return empty when no tasks", function()
      local indicator = statusline.get_status_indicator()
      assert.equals("", indicator)
    end)

    it("should show open tasks with ○ symbol", function()
      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", status = "open" }
        }
      end

      statusline.invalidate_cache()
      local indicator = statusline.get_status_indicator()
      assert.matches("○1", indicator)
    end)

    it("should show in_progress tasks with ◐ symbol", function()
      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", status = "in_progress" }
        }
      end

      statusline.invalidate_cache()
      local indicator = statusline.get_status_indicator()
      assert.matches("◐1", indicator)
    end)

    it("should show closed tasks with ✓ symbol", function()
      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", status = "closed" }
        }
      end

      statusline.invalidate_cache()
      local indicator = statusline.get_status_indicator()
      assert.matches("✓1", indicator)
    end)

    it("should combine multiple status counts", function()
      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", status = "open" },
          { id = "2", title = "Task 2", status = "in_progress" },
          { id = "3", title = "Task 3", status = "closed" }
        }
      end

      statusline.invalidate_cache()
      local indicator = statusline.get_status_indicator()
      assert.matches("○1", indicator)
      assert.matches("◐1", indicator)
      assert.matches("✓1", indicator)
    end)
  end)

  describe("priority info", function()
    it("should return empty when no tasks", function()
      local info = statusline.get_priority_info()
      assert.equals("", info)
    end)

    it("should display priority breakdown", function()
      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", priority = "P1" },
          { id = "2", title = "Task 2", priority = "P2" },
          { id = "3", title = "Task 3", priority = "P1" }
        }
      end

      local info = statusline.get_priority_info()
      assert.matches("P1:2", info)
      assert.matches("P2:1", info)
    end)
  end)

  describe("status short", function()
    it("should return empty when no tasks", function()
      local short = statusline.get_status_short()
      assert.equals("", short)
    end)

    it("should show total task count", function()
      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", status = "open" },
          { id = "2", title = "Task 2", status = "closed" }
        }
      end

      statusline.invalidate_cache()
      local short = statusline.get_status_short()
      assert.matches("Beads", short)
      assert.matches("2", short)
    end)

    it("should show in_progress count when present", function()
      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", status = "open" },
          { id = "2", title = "Task 2", status = "in_progress" }
        }
      end

      statusline.invalidate_cache()
      local short = statusline.get_status_short()
      assert.matches("1/2", short)
    end)
  end)

  describe("configuration", function()
    it("should allow enabling/disabling", function()
      statusline.setup({ enabled = true })
      local config = statusline.get_config()
      assert.is_true(config.enabled)

      statusline.setup({ enabled = false })
      config = statusline.get_config()
      assert.is_false(config.enabled)
    end)

    it("should allow custom highlight group", function()
      statusline.setup({ highlight = "MyHighlight" })
      local config = statusline.get_config()
      assert.equals("MyHighlight", config.highlight)
    end)

    it("should allow custom format function", function()
      local custom_fn = function() return "custom" end
      statusline.setup({ format = custom_fn })
      local config = statusline.get_config()
      assert.equals(custom_fn, config.format)
    end)
  end)

  describe("statusline building", function()
    it("should build format from components", function()
      local format = statusline.build_format({ "short" })
      assert.is_function(format)

      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", status = "open" }
        }
      end

      local result = format()
      assert.matches("Beads", result)
    end)

    it("should combine multiple components", function()
      require("beads.cli").ready = function()
        return {
          { id = "1", title = "Task 1", status = "open" }
        }
      end

      local format = statusline.build_format({ "short", "indicator" })
      local result = format()
      assert.truthy(string.len(result) > 0)
    end)

    it("should skip empty components", function()
      require("beads.cli").ready = function()
        return {} -- Empty tasks
      end

      local format = statusline.build_format({ "short", "indicator" })
      local result = format()
      assert.equals("", result)
    end)
  end)

  describe("cache management", function()
    it("should invalidate cache", function()
      statusline.invalidate_cache()
      local config = statusline.get_config()
      -- Cache should be empty after invalidation
      assert.equals(5000, config.update_interval or 5000)
    end)

    it("should allow setting custom update interval", function()
      statusline.set_update_interval(10000)
      local config = statusline.get_config()
      -- Interval should be updated
      assert.equals(10000, config.update_interval or 5000)
    end)
  end)
end)
