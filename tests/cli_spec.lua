-- Tests for beads CLI module

describe("beads.cli", function()
  local cli = require("beads.cli")

  describe("ready()", function()
    it("should return a list of tasks", function()
      local tasks = cli.ready()
      assert.is_table(tasks)
    end)
  end)

  describe("show()", function()
    it("should return task details", function()
      -- This test would require a real task ID
      -- Skipping for now as it requires actual Beads setup
      pending("requires actual Beads instance")
    end)
  end)

  describe("create()", function()
    it("should create a task with required title", function()
      pending("requires actual Beads instance")
    end)

    it("should handle optional description", function()
      pending("requires actual Beads instance")
    end)
  end)

  describe("update()", function()
    it("should update task status", function()
      pending("requires actual Beads instance")
    end)
  end)

  describe("close()", function()
    it("should close a task", function()
      pending("requires actual Beads instance")
    end)
  end)
end)
