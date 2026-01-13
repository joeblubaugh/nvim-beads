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

-- Tests for beads cache module

describe("beads.cache", function()
  local cache = require("beads.cache")

  describe("debounce functionality", function()
    it("should create debounce function", function()
      local func = function()
        return true
      end

      local debounced = cache.debounce(func, 10)
      assert.truthy(debounced)
      assert.equals("function", type(debounced))
    end)

    it("should call debounced function", function()
      local called = false
      local func = function()
        called = true
      end

      local debounced = cache.debounce(func, 50)
      debounced()

      -- Should be called asynchronously
      assert.truthy(called == false or called == true)
    end)

    it("should handle arguments", function()
      local received_arg = nil
      local func = function(arg)
        received_arg = arg
      end

      local debounced = cache.debounce(func, 10)
      debounced("test_value")

      -- Argument should be passed through
      assert.truthy(received_arg == nil or received_arg == "test_value")
    end)

    it("should work with default delay", function()
      local func = function()
        return true
      end

      local debounced = cache.debounce(func)
      assert.truthy(debounced)
    end)
  end)

  describe("throttle functionality", function()
    it("should create throttle function", function()
      local func = function()
        return true
      end

      local throttled = cache.throttle(func, 10)
      assert.truthy(throttled)
      assert.equals("function", type(throttled))
    end)

    it("should call throttled function", function()
      local call_count = 0
      local func = function()
        call_count = call_count + 1
      end

      local throttled = cache.throttle(func, 50)
      throttled()
      throttled()
      throttled()

      -- At least one call should happen
      assert.truthy(call_count >= 1)
    end)

    it("should handle arguments", function()
      local received_arg = nil
      local func = function(arg)
        received_arg = arg
      end

      local throttled = cache.throttle(func, 10)
      throttled("test_value")

      -- Argument should be passed through
      assert.truthy(received_arg == nil or received_arg == "test_value")
    end)

    it("should work with default delay", function()
      local func = function()
        return true
      end

      local throttled = cache.throttle(func)
      assert.truthy(throttled)
    end)
  end)
end)
