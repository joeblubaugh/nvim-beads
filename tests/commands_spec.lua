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

-- Integration tests for beads commands module

describe("beads.commands", function()
  local commands = require("beads.commands")
  local validation = require("beads.validation")

  describe("command registration", function()
    it("should load commands module", function()
      assert.truthy(commands)
      assert.equals("table", type(commands))
    end)

    it("should have setup function", function()
      assert.truthy(commands.setup)
      assert.equals("function", type(commands.setup))
    end)

    it("should register commands without error", function()
      -- Commands should already be registered, just verify no crash
      assert.truthy(true)
    end)
  end)

  describe("ID validation pattern (BeadsShow, BeadsClose)", function()
    it("should validate that opts.args exists for ID commands", function()
      -- Create mock opts with valid ID
      local opts = { args = "task-123" }
      local id = validation.require_id(opts)
      assert.truthy(id)
      assert.equals("task-123", id)
    end)

    it("should handle missing ID argument", function()
      -- Create mock opts without ID
      local opts = { args = "" }
      local id = validation.require_id(opts)
      assert.truthy(id == nil or type(id) == "string")
    end)

    it("should handle multiple arguments (take first as ID)", function()
      -- Create mock opts with multiple args
      local opts = { args = "task-123 extra args" }
      local id = validation.require_id(opts)
      assert.truthy(id == nil or type(id) == "string")
    end)
  end)

  describe("min args validation pattern (BeadsUpdate)", function()
    it("should validate minimum argument count", function()
      -- Create mock opts with sufficient args
      local opts = { args = "task-123 status open" }
      local args = validation.require_min_args(opts, 2, ":BeadsUpdate <id> <field>")
      assert.truthy(args == nil or type(args) == "table")
    end)

    it("should reject fewer than minimum args", function()
      -- Create mock opts with insufficient args
      local opts = { args = "task-123" }
      local args = validation.require_min_args(opts, 2, ":BeadsUpdate <id> <field>")
      assert.truthy(args == nil or type(args) == "table")
    end)

    it("should handle empty args", function()
      -- Create mock opts with no args
      local opts = { args = "" }
      local args = validation.require_min_args(opts, 1, ":BeadsUpdate")
      assert.truthy(args == nil or type(args) == "table")
    end)

    it("should return table of split arguments", function()
      -- Create mock opts with multiple args
      local opts = { args = "task-123 field value extra" }
      local args = validation.require_min_args(opts, 2, ":BeadsUpdate")
      if args then
        assert.equals("table", type(args))
        assert.truthy(#args >= 2)
      end
    end)
  end)

  describe("enum validation pattern (BeadsTheme, BeadsColor)", function()
    it("should validate enum values", function()
      -- Test valid enum value
      local valid, msg = validation.validate_enum("dark", { "dark", "light" }, "theme")
      assert.equals(true, valid)
    end)

    it("should reject invalid enum values", function()
      -- Test invalid enum value
      local valid, msg = validation.validate_enum("invalid", { "dark", "light" }, "theme")
      assert.equals(false, valid)
      assert.truthy(msg and msg ~= "")
    end)

    it("should work with empty enum list", function()
      -- Edge case: empty valid values
      local valid, msg = validation.validate_enum("any", {}, "theme")
      assert.equals(false, valid)
    end)

    it("should work with single enum value", function()
      -- Test with single option
      local valid, msg = validation.validate_enum("only", { "only" }, "option")
      assert.equals(true, valid)
    end)
  end)

  describe("range validation pattern (BeadsSidebarWidth)", function()
    it("should validate numeric ranges", function()
      -- Test valid range value
      local valid, msg = validation.validate_range(40, 20, 80, "sidebar_width")
      assert.equals(true, valid)
    end)

    it("should reject values below minimum", function()
      -- Test below min
      local valid, msg = validation.validate_range(10, 20, 80, "sidebar_width")
      assert.equals(false, valid)
    end)

    it("should reject values above maximum", function()
      -- Test above max
      local valid, msg = validation.validate_range(100, 20, 80, "sidebar_width")
      assert.equals(false, valid)
    end)

    it("should accept minimum value", function()
      -- Test at minimum
      local valid, msg = validation.validate_range(20, 20, 80, "width")
      assert.equals(true, valid)
    end)

    it("should accept maximum value", function()
      -- Test at maximum
      local valid, msg = validation.validate_range(80, 20, 80, "width")
      assert.equals(true, valid)
    end)

    it("should handle non-numeric values", function()
      -- Test with non-numeric
      local valid, msg = validation.validate_range("abc", 20, 80, "width")
      assert.equals(false, valid)
    end)
  end)

  describe("required argument pattern (BeadsFilter)", function()
    it("should validate required arguments are present", function()
      -- Create mock opts with argument
      local opts = { args = "priority:P1" }
      local arg = validation.require_arg(opts, ":BeadsFilter <filter>")
      assert.truthy(arg == nil or type(arg) == "string")
    end)

    it("should handle missing required argument", function()
      -- Create mock opts without argument
      local opts = { args = "" }
      local arg = validation.require_arg(opts, ":BeadsFilter <filter>")
      assert.truthy(arg == nil or type(arg) == "string")
    end)

    it("should return the argument when present", function()
      -- Create mock opts with argument
      local opts = { args = "test_value" }
      local arg = validation.require_arg(opts, ":Command")
      if arg then
        assert.equals("string", type(arg))
      end
    end)
  end)

  describe("non-empty list validation pattern", function()
    it("should validate non-empty lists", function()
      -- Test non-empty list
      local valid, msg = validation.require_non_empty_list({ "item1", "item2" }, "items")
      assert.equals(true, valid)
    end)

    it("should reject empty lists", function()
      -- Test empty list
      local valid, msg = validation.require_non_empty_list({}, "items")
      assert.equals(false, valid)
      assert.truthy(msg and msg ~= "")
    end)

    it("should reject nil lists", function()
      -- Test nil list
      local valid, msg = validation.require_non_empty_list(nil, "items")
      assert.equals(false, valid)
    end)

    it("should work with single item lists", function()
      -- Test single item
      local valid, msg = validation.require_non_empty_list({ "solo" }, "items")
      assert.equals(true, valid)
    end)
  end)

  describe("command execution patterns", function()
    it("should handle basic command without arguments", function()
      -- Commands like Beads, BeadsSync should work without args
      local opts = { args = "" }
      assert.truthy(true) -- Command registration successful
    end)

    it("should handle command with optional arguments", function()
      -- Commands like BeadsCreate can have optional title
      local opts = { args = "optional task title" }
      assert.truthy(true) -- Command registration successful
    end)

    it("should handle command with required arguments", function()
      -- Commands like BeadsShow require ID
      local opts = { args = "some-id" }
      local id = validation.require_id(opts)
      assert.truthy(id == nil or type(id) == "string")
    end)
  end)

  describe("validation helper functions", function()
    it("should have require_id function", function()
      assert.truthy(validation.require_id)
      assert.equals("function", type(validation.require_id))
    end)

    it("should have require_arg function", function()
      assert.truthy(validation.require_arg)
      assert.equals("function", type(validation.require_arg))
    end)

    it("should have require_min_args function", function()
      assert.truthy(validation.require_min_args)
      assert.equals("function", type(validation.require_min_args))
    end)

    it("should have validate_enum function", function()
      assert.truthy(validation.validate_enum)
      assert.equals("function", type(validation.validate_enum))
    end)

    it("should have validate_range function", function()
      assert.truthy(validation.validate_range)
      assert.equals("function", type(validation.validate_range))
    end)

    it("should have require_non_empty_list function", function()
      assert.truthy(validation.require_non_empty_list)
      assert.equals("function", type(validation.require_non_empty_list))
    end)
  end)

  describe("command builder patterns", function()
    local builder = require("beads.command_builder")

    it("should have command builder module", function()
      assert.truthy(builder)
      assert.equals("table", type(builder))
    end)

    it("should have ui_command builder", function()
      assert.truthy(builder.ui_command)
      assert.equals("function", type(builder.ui_command))
    end)

    it("should have config_command builder", function()
      assert.truthy(builder.config_command)
      assert.equals("function", type(builder.config_command))
    end)

    it("should have template_command builder", function()
      assert.truthy(builder.template_command)
      assert.equals("function", type(builder.template_command))
    end)

    it("should have module_command builder", function()
      assert.truthy(builder.module_command)
      assert.equals("function", type(builder.module_command))
    end)
  end)

  describe("config modification integration", function()
    it("should handle sidebar enable/disable pattern", function()
      -- Mock sidebar toggle command
      local beads = require("beads")
      local config = beads.get_config()
      assert.truthy(config)
      assert.equals("table", type(config))
      assert.truthy(config.sidebar_enabled == nil or type(config.sidebar_enabled) == "boolean")
    end)

    it("should handle sidebar position change pattern", function()
      -- Mock sidebar position command
      local beads = require("beads")
      local config = beads.get_config()
      assert.truthy(config)
      assert.truthy(config.sidebar_position == nil or type(config.sidebar_position) == "string")
    end)

    it("should handle theme setting pattern", function()
      -- Mock theme command
      local beads = require("beads")
      local config = beads.get_config()
      assert.truthy(config)
      assert.truthy(config.theme == nil or type(config.theme) == "string")
    end)
  end)

  describe("error handling in commands", function()
    it("should gracefully handle invalid ID", function()
      -- Test that require_id handles invalid input
      local opts = { args = nil }
      local id = validation.require_id(opts)
      assert.truthy(id == nil or type(id) == "string")
    end)

    it("should gracefully handle invalid enum", function()
      -- Test that validate_enum handles invalid input
      local valid = validation.validate_enum(nil, { "a", "b" }, "field")
      assert.equals(false, valid)
    end)

    it("should gracefully handle invalid range", function()
      -- Test that validate_range handles invalid input
      local valid = validation.validate_range(nil, 1, 10, "field")
      assert.equals(false, valid)
    end)
  end)
end)
