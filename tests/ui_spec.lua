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

-- Tests for beads UI module

describe("beads.ui", function()
  local ui = require("beads.ui")

  describe("filter state management", function()
    it("should initialize with empty filters", function()
      local state = ui.get_filter_state()
      assert.is_table(state)
      assert.are.same({}, state.priority)
      assert.are.same({}, state.status)
      assert.are.same({}, state.assignee)
    end)

    it("should clear all filters", function()
      ui.set_filter_state({
        priority = {"P1"},
        status = {"open"},
        assignee = {"alice"}
      })
      ui.clear_filters()
      local state = ui.get_filter_state()
      assert.are.same({}, state.priority)
      assert.are.same({}, state.status)
      assert.are.same({}, state.assignee)
    end)

    it("should toggle filter values", function()
      ui.clear_filters()
      ui.toggle_filter("priority", "P1")
      local state = ui.get_filter_state()
      assert.are.same({"P1"}, state.priority)

      -- Toggle again to remove
      ui.toggle_filter("priority", "P1")
      state = ui.get_filter_state()
      assert.are.same({}, state.priority)
    end)

    it("should support multiple filters", function()
      ui.clear_filters()
      ui.toggle_filter("priority", "P1")
      ui.toggle_filter("priority", "P2")
      ui.toggle_filter("status", "open")
      local state = ui.get_filter_state()
      assert.equals(2, #state.priority)
      assert.equals(1, #state.status)
    end)
  end)

  describe("search functionality", function()
    it("should set and get search query", function()
      ui.set_search_query("test query")
      assert.equals("test query", ui.get_search_query())
    end)

    it("should clear search query", function()
      ui.set_search_query("test query")
      ui.set_search_query(nil)
      assert.is_nil(ui.get_search_query())
    end)
  end)

  describe("sync state management", function()
    it("should set sync state to syncing", function()
      ui.set_sync_state("syncing")
      -- Just verify it doesn't error
      assert.is_true(true)
    end)

    it("should set sync state to synced", function()
      ui.set_sync_state("synced")
      -- Verify it doesn't error
      assert.is_true(true)
    end)

    it("should set sync state to failed", function()
      ui.set_sync_state("failed")
      -- Verify it doesn't error
      assert.is_true(true)
    end)

    it("should set sync state to idle", function()
      ui.set_sync_state("idle")
      -- Verify it doesn't error
      assert.is_true(true)
    end)
  end)

  describe("sidebar toggle", function()
    it("should toggle sidebar visibility without error", function()
      -- This would require a valid window ID, so we just verify it doesn't crash
      -- The actual toggle behavior requires Neovim context
      pending("requires Neovim context for window management")
    end)
  end)

  describe("ui initialization", function()
    it("should initialize without error", function()
      ui.init()
      assert.is_true(true)
    end)
  end)

  describe("filter string parsing", function()
    it("should parse filter strings with single values", function()
      ui.clear_filters()
      ui.apply_filter_string("priority:P1")
      local state = ui.get_filter_state()
      assert.equals(1, #state.priority)
      assert.equals("P1", state.priority[1])
    end)

    it("should parse filter strings with multiple values", function()
      ui.clear_filters()
      ui.apply_filter_string("priority:P1,priority:P2")
      local state = ui.get_filter_state()
      assert.equals(2, #state.priority)
    end)

    it("should parse different filter types together", function()
      ui.clear_filters()
      ui.apply_filter_string("priority:P1,status:open")
      local state = ui.get_filter_state()
      assert.equals(1, #state.priority)
      assert.equals(1, #state.status)
    end)

    it("should handle filter strings with spaces", function()
      ui.clear_filters()
      ui.apply_filter_string("priority: P1 , status: open")
      local state = ui.get_filter_state()
      assert.equals(1, #state.priority)
      assert.equals(1, #state.status)
    end)
  end)
end)
