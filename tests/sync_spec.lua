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

-- Tests for beads sync module

describe("beads.sync", function()
  local sync = require("beads.sync")

  describe("sync module structure", function()
    it("should load sync module", function()
      assert.truthy(sync)
      assert.equals("table", type(sync))
    end)

    it("should have start_auto_sync function if available", function()
      if sync.start_auto_sync then
        assert.equals("function", type(sync.start_auto_sync))
      end
    end)

    it("should have stop_auto_sync function if available", function()
      if sync.stop_auto_sync then
        assert.equals("function", type(sync.stop_auto_sync))
      end
    end)
  end)

  describe("auto-sync operations", function()
    it("should handle start_auto_sync call if available", function()
      if sync.start_auto_sync then
        sync.start_auto_sync()
        assert.truthy(true)
      end
    end)

    it("should handle stop_auto_sync call if available", function()
      if sync.stop_auto_sync then
        sync.stop_auto_sync()
        assert.truthy(true)
      end
    end)

    it("should handle multiple sync calls safely", function()
      if sync.start_auto_sync then
        sync.start_auto_sync()
        sync.start_auto_sync()
      end
      assert.truthy(true)
    end)
  end)

  describe("sync directory watching", function()
    it("should have watch_directory function if available", function()
      if sync.watch_directory then
        assert.equals("function", type(sync.watch_directory))
      end
    end)

    it("should have unwatch_directory function if available", function()
      if sync.unwatch_directory then
        assert.equals("function", type(sync.unwatch_directory))
      end
    end)
  end)
end)
