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

-- Tests for beads theme module

describe("beads.theme", function()
  local theme = require("beads.theme")

  describe("theme selection", function()
    it("should have dark theme available", function()
      local themes = theme.get_available_themes()
      assert.truthy(vim.tbl_contains(themes, "dark"))
    end)

    it("should have light theme available", function()
      local themes = theme.get_available_themes()
      assert.truthy(vim.tbl_contains(themes, "light"))
    end)

    it("should set theme correctly", function()
      theme.set_theme("dark")
      assert.equals("dark", theme.get_current_theme())

      theme.set_theme("light")
      assert.equals("light", theme.get_current_theme())
    end)

    it("should reject unknown theme", function()
      local current = theme.get_current_theme()
      theme.set_theme("unknown_theme")
      -- Should still be the same theme
      assert.equals(current, theme.get_current_theme())
    end)
  end)

  describe("color management", function()
    it("should get colors for current theme", function()
      theme.set_theme("dark")
      local colors = theme.get_colors()
      assert.truthy(colors.open)
      assert.truthy(colors.in_progress)
      assert.truthy(colors.closed)
    end)

    it("should support dark theme colors", function()
      theme.set_theme("dark")
      local colors = theme.get_colors()
      assert.truthy(colors.bg)
      assert.truthy(colors.fg)
      assert.truthy(colors.P1)
      assert.truthy(colors.P2)
      assert.truthy(colors.P3)
    end)

    it("should support light theme colors", function()
      theme.set_theme("light")
      local colors = theme.get_colors()
      assert.truthy(colors.bg)
      assert.truthy(colors.fg)
      assert.truthy(colors.P1)
      assert.truthy(colors.P2)
      assert.truthy(colors.P3)
    end)

    it("should have different colors for dark and light", function()
      theme.set_theme("dark")
      local dark_colors = theme.get_colors()

      theme.set_theme("light")
      local light_colors = theme.get_colors()

      -- At least some colors should be different
      assert.is_false(dark_colors.bg == light_colors.bg)
    end)
  end)

  describe("custom colors", function()
    it("should allow setting custom color", function()
      theme.set_color("P1", "#ff0000")
      local colors = theme.get_colors()
      assert.equals("#ff0000", colors.P1)
    end)

    it("should override theme color", function()
      theme.set_theme("dark")
      local original = theme.get_color("P1")

      theme.set_color("P1", "#123456")
      assert.equals("#123456", theme.get_color("P1"))

      -- Reset
      theme.set_color("P1", original)
    end)

    it("should get individual color", function()
      theme.set_color("open", "#0066cc")
      assert.equals("#0066cc", theme.get_color("open"))
    end)
  end)

  describe("auto-detection", function()
    it("should auto-detect theme", function()
      theme.auto_detect()
      -- Should have a valid theme set
      assert.truthy(theme.get_current_theme())
    end)

    it("should set light or dark theme", function()
      theme.auto_detect()
      local current = theme.get_current_theme()
      assert.truthy(current == "light" or current == "dark")
    end)
  end)

  describe("available themes", function()
    it("should return list of themes", function()
      local available = theme.get_available_themes()
      assert.truthy(type(available) == "table")
      assert.truthy(#available > 0)
    end)

    it("should always have at least two themes", function()
      local available = theme.get_available_themes()
      assert.truthy(#available >= 2)
    end)
  end)

  describe("custom theme registration", function()
    it("should register custom theme", function()
      local custom_colors = {
        bg = "#000000",
        fg = "#ffffff",
        open = "#00ff00",
        in_progress = "#ffff00",
        closed = "#ff0000",
        P1 = "#ff0000",
        P2 = "#ffff00",
        P3 = "#00ff00",
      }
      theme.register_theme("custom", custom_colors)

      theme.set_theme("custom")
      assert.equals("custom", theme.get_current_theme())
    end)
  end)
end)
