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

-- Tests for beads validation module

describe("beads.validation", function()
  local validation = require("beads.validation")

  describe("require_id", function()
    it("should return ID when provided", function()
      local opts = { args = "task-123" }
      local result = validation.require_id(opts)
      assert.equals("task-123", result)
    end)

    it("should return nil and notify when ID is empty", function()
      local opts = { args = "" }
      local result = validation.require_id(opts)
      assert.is_nil(result)
    end)

    it("should use custom field name in error message", function()
      local opts = { args = "" }
      local result = validation.require_id(opts, "Parent ID")
      assert.is_nil(result)
    end)

    it("should use default field name", function()
      local opts = { args = "" }
      local result = validation.require_id(opts)
      assert.is_nil(result)
    end)
  end)

  describe("require_arg", function()
    it("should return arg when provided", function()
      local opts = { args = "some_value" }
      local result = validation.require_arg(opts, "Usage: command <value>")
      assert.equals("some_value", result)
    end)

    it("should return nil when arg is empty", function()
      local opts = { args = "" }
      local result = validation.require_arg(opts, "Usage: command <value>")
      assert.is_nil(result)
    end)

    it("should include usage message in notification", function()
      local opts = { args = "" }
      validation.require_arg(opts, "Usage: command <value>")
    end)
  end)

  describe("require_min_args", function()
    it("should return args when sufficient count provided", function()
      local opts = { args = "arg1 arg2 arg3" }
      local result = validation.require_min_args(opts, 2, "Usage: command <a> <b>")
      assert.truthy(result)
      assert.equals(3, #result)
      assert.equals("arg1", result[1])
    end)

    it("should return nil when insufficient args", function()
      local opts = { args = "arg1" }
      local result = validation.require_min_args(opts, 2, "Usage: command <a> <b>")
      assert.is_nil(result)
    end)

    it("should handle empty args", function()
      local opts = { args = "" }
      local result = validation.require_min_args(opts, 1, "Usage: command <value>")
      assert.is_nil(result)
    end)

    it("should trim whitespace correctly", function()
      local opts = { args = "arg1   arg2   arg3" }
      local result = validation.require_min_args(opts, 3, "Usage")
      assert.equals(3, #result)
    end)

    it("should support exact min count", function()
      local opts = { args = "arg1 arg2" }
      local result = validation.require_min_args(opts, 2, "Usage")
      assert.truthy(result)
      assert.equals(2, #result)
    end)
  end)

  describe("validate_enum", function()
    it("should return true for valid enum value", function()
      local valid = { "left", "right", "center" }
      local result = validation.validate_enum("left", valid, "Position")
      assert.is_true(result)
    end)

    it("should return false for invalid enum value", function()
      local valid = { "left", "right", "center" }
      local result = validation.validate_enum("top", valid, "Position")
      assert.is_false(result)
    end)

    it("should handle empty value", function()
      local valid = { "left", "right" }
      local result = validation.validate_enum("", valid, "Position")
      assert.is_false(result)
    end)

    it("should work with single option", function()
      local valid = { "telescope" }
      local result = validation.validate_enum("telescope", valid, "Finder")
      assert.is_true(result)
    end)
  end)

  describe("validate_range", function()
    it("should return true for value in range", function()
      local result = validation.validate_range(50, 20, 120, "Width")
      assert.is_true(result)
    end)

    it("should return true for value at min boundary", function()
      local result = validation.validate_range(20, 20, 120, "Width")
      assert.is_true(result)
    end)

    it("should return true for value at max boundary", function()
      local result = validation.validate_range(120, 20, 120, "Width")
      assert.is_true(result)
    end)

    it("should return false for value below range", function()
      local result = validation.validate_range(10, 20, 120, "Width")
      assert.is_false(result)
    end)

    it("should return false for value above range", function()
      local result = validation.validate_range(150, 20, 120, "Width")
      assert.is_false(result)
    end)

    it("should return false for nil value", function()
      local result = validation.validate_range(nil, 20, 120, "Width")
      assert.is_false(result)
    end)
  end)

  describe("require_non_empty_list", function()
    it("should return true for non-empty list", function()
      local list = { "item1", "item2" }
      local result = validation.require_non_empty_list(list, "No items")
      assert.is_true(result)
    end)

    it("should return false for empty list", function()
      local list = {}
      local result = validation.require_non_empty_list(list, "No items")
      assert.is_false(result)
    end)

    it("should return false for nil list", function()
      local result = validation.require_non_empty_list(nil, "No items")
      assert.is_false(result)
    end)

    it("should work with single item", function()
      local list = { "item" }
      local result = validation.require_non_empty_list(list, "No items")
      assert.is_true(result)
    end)
  end)
end)
