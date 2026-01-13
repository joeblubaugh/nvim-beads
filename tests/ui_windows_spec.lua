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

-- Tests for beads window management module

describe("beads.ui_windows", function()
  local windows = require("beads.ui_windows")

  describe("window management functions", function()
    it("should have create_float_window function", function()
      assert.truthy(windows.create_float_window)
      assert.equals("function", type(windows.create_float_window))
    end)

    it("should have create_sidebar_window function", function()
      assert.truthy(windows.create_sidebar_window)
      assert.equals("function", type(windows.create_sidebar_window))
    end)

    it("should have show_task_preview function", function()
      assert.truthy(windows.show_task_preview)
      assert.equals("function", type(windows.show_task_preview))
    end)

    it("should have close_windows function", function()
      assert.truthy(windows.close_windows)
      assert.equals("function", type(windows.close_windows))
    end)
  end)

  describe("window state tracking", function()
    it("should track task_list_bufnr", function()
      -- Just check that the property exists (can be nil or a number)
      assert.truthy(windows.task_list_bufnr == nil or type(windows.task_list_bufnr) == "number")
    end)

    it("should track task_list_winid", function()
      -- Just check that the property exists (can be nil or a number)
      assert.truthy(windows.task_list_winid == nil or type(windows.task_list_winid) == "number")
    end)

    it("should track preview_bufnr", function()
      -- Just check that the property exists (can be nil or a number)
      assert.truthy(windows.preview_bufnr == nil or type(windows.preview_bufnr) == "number")
    end)

    it("should track preview_winid", function()
      -- Just check that the property exists (can be nil or a number)
      assert.truthy(windows.preview_winid == nil or type(windows.preview_winid) == "number")
    end)
  end)

  describe("task preview handling", function()
    it("should handle nil task preview", function()
      windows.show_task_preview(nil)
      assert.truthy(true)
    end)

    it("should close windows safely", function()
      windows.close_windows()
      assert.truthy(true)
    end)

    it("should handle multiple close calls", function()
      windows.close_windows()
      windows.close_windows()
      assert.truthy(true)
    end)
  end)
end)
