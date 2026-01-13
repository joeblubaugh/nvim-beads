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

-- Tests for beads error handling module

describe("beads.error_handling", function()
  local error_handling = require("beads.error_handling")

  describe("safe_require", function()
    it("should require a valid module", function()
      local result = error_handling.safe_require("beads.validation")
      assert.truthy(result)
      assert.truthy(result.require_id)
    end)

    it("should return fallback for invalid module", function()
      local fallback = {}
      local result = error_handling.safe_require("beads.nonexistent", fallback)
      assert.equals(fallback, result)
    end)

    it("should return nil if no fallback provided", function()
      local result = error_handling.safe_require("beads.nonexistent")
      assert.is_nil(result)
    end)
  end)

  describe("safe_callback", function()
    it("should call valid callback", function()
      local called = false
      local callback = function()
        called = true
      end

      local result = error_handling.safe_callback(callback)
      assert.is_true(result)
      assert.is_true(called)
    end)

    it("should pass arguments to callback", function()
      local received_arg = nil
      local callback = function(arg)
        received_arg = arg
      end

      error_handling.safe_callback(callback, "test_value")
      assert.equals("test_value", received_arg)
    end)

    it("should return false for nil callback", function()
      local result = error_handling.safe_callback(nil)
      assert.is_false(result)
    end)

    it("should handle callback errors gracefully", function()
      local callback = function()
        error("Test error")
      end

      local result = error_handling.safe_callback(callback)
      assert.is_false(result)
    end)
  end)

  describe("safe_api_call", function()
    it("should call valid API function", function()
      local api_func = function(a, b)
        return a + b
      end

      local result, err = error_handling.safe_api_call(api_func, 2, 3)
      assert.equals(5, result)
      assert.is_nil(err)
    end)

    it("should return error for failed API call", function()
      local api_func = function()
        error("API error")
      end

      local result, err = error_handling.safe_api_call(api_func)
      assert.is_nil(result)
      assert.truthy(err)
      assert.matches("API call failed", err)
    end)

    it("should handle nil return", function()
      local api_func = function()
        return nil
      end

      local result, err = error_handling.safe_api_call(api_func)
      assert.is_nil(result)
      assert.is_nil(err)
    end)
  end)

  describe("validate_dimensions", function()
    it("should accept valid dimensions", function()
      -- Using reasonable values less than terminal size
      local valid, err = error_handling.validate_dimensions(40, 20)
      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it("should reject zero width", function()
      local valid, err = error_handling.validate_dimensions(0, 20)
      assert.is_false(valid)
      assert.truthy(err)
    end)

    it("should reject negative height", function()
      local valid, err = error_handling.validate_dimensions(40, -5)
      assert.is_false(valid)
      assert.truthy(err)
    end)

    it("should reject nil width", function()
      local valid, err = error_handling.validate_dimensions(nil, 20)
      assert.is_false(valid)
      assert.truthy(err)
    end)

    it("should reject width exceeding columns", function()
      local cols = vim.o.columns
      local valid, err = error_handling.validate_dimensions(cols + 10, 20)
      assert.is_false(valid)
      assert.truthy(err)
    end)
  end)

  describe("validate_id", function()
    it("should accept valid ID", function()
      local valid, err = error_handling.validate_id("task-123")
      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it("should reject empty ID", function()
      local valid, err = error_handling.validate_id("")
      assert.is_false(valid)
      assert.truthy(err)
    end)

    it("should reject nil ID", function()
      local valid, err = error_handling.validate_id(nil)
      assert.is_false(valid)
      assert.truthy(err)
    end)

    it("should use custom field name in error", function()
      local valid, err = error_handling.validate_id("", "Parent ID")
      assert.is_false(valid)
      assert.matches("Parent ID", err)
    end)

    it("should use default field name", function()
      local valid, err = error_handling.validate_id("")
      assert.is_false(valid)
      assert.matches("ID", err)
    end)
  end)

  describe("get_error_message", function()
    it("should return nil for success", function()
      local result = error_handling.get_error_message(true, "data")
      assert.is_nil(result)
    end)

    it("should return error message for failure", function()
      local result = error_handling.get_error_message(false, "error message")
      assert.equals("error message", result)
    end)

    it("should convert result to string for failure", function()
      local result = error_handling.get_error_message(false, 123)
      assert.equals("123", result)
    end)

    it("should handle nil error message", function()
      local result = error_handling.get_error_message(false, nil)
      assert.equals("unknown error", result)
    end)
  end)
end)
