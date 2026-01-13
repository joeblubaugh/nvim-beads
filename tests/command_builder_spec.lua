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

-- Tests for beads command builder module

describe("beads.command_builder", function()
  local builder = require("beads.command_builder")

  describe("ui_command", function()
    it("should build command that calls ui function without validation", function()
      local called = false
      local ui_func = function()
        called = true
      end

      local handler = builder.ui_command(ui_func, nil)
      handler({})

      assert.is_true(called)
    end)

    it("should build command that validates before calling ui function", function()
      local called = false
      local called_with = nil

      local ui_func = function(arg)
        called = true
        called_with = arg
      end

      local validator = function(opts)
        if opts.args == "" then return nil end
        return opts.args
      end

      local handler = builder.ui_command(ui_func, validator)
      handler({ args = "test-value" })

      assert.is_true(called)
      assert.equals("test-value", called_with)
    end)

    it("should not call ui function if validation fails", function()
      local called = false
      local ui_func = function()
        called = true
      end

      local validator = function(opts)
        if opts.args == "" then return nil end
        return opts.args
      end

      local handler = builder.ui_command(ui_func, validator)
      handler({ args = "" })

      assert.is_false(called)
    end)
  end)

  describe("config_command", function()
    it("should build command that gets, modifies, and saves config", function()
      local handler = builder.config_command("test_key", function(opts, config)
        if opts.args == "" then return nil end
        return opts.args, "Config updated"
      end)

      assert.truthy(handler)
    end)

    it("should not proceed if transformer returns nil", function()
      local handler = builder.config_command("test_key", function(opts, config)
        return nil, nil
      end)

      handler({ args = "" })
    end)
  end)

  describe("template_command", function()
    it("should build command that creates task from template", function()
      local handler = builder.template_command("bug")
      assert.truthy(handler)
    end)

    it("should notify if template not found", function()
      local handler = builder.template_command("nonexistent")
      handler({})
    end)
  end)

  describe("module_command", function()
    it("should build command that calls module function", function()
      local handler = builder.module_command(
        "beads.validation",
        "require_non_empty_list",
        nil,
        nil
      )

      assert.truthy(handler)
    end)

    it("should use validator if provided", function()
      local validator = function(opts)
        if opts.args == "" then return nil end
        return opts.args
      end

      local handler = builder.module_command(
        "beads.validation",
        "require_non_empty_list",
        validator,
        nil
      )

      assert.truthy(handler)
    end)

    it("should format success message if formatter provided", function()
      local msg_formatter = function(value)
        return "Success: " .. value
      end

      local handler = builder.module_command(
        "beads.validation",
        "require_non_empty_list",
        nil,
        msg_formatter
      )

      assert.truthy(handler)
    end)
  end)
end)
