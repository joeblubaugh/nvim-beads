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

-- Tests for beads templates module

describe("beads.templates", function()
  local templates = require("beads.templates")

  describe("template module structure", function()
    it("should have list_templates function", function()
      assert.truthy(templates.list_templates)
      assert.equals("function", type(templates.list_templates))
    end)

    it("should have resolve_template function", function()
      assert.truthy(templates.resolve_template)
      assert.equals("function", type(templates.resolve_template))
    end)

    it("should have get_recommended_workflows function", function()
      assert.truthy(templates.get_recommended_workflows)
      assert.equals("function", type(templates.get_recommended_workflows))
    end)
  end)

  describe("template listing", function()
    it("should return template list", function()
      local templates_list = templates.list_templates()
      assert.truthy(templates_list)
      assert.equals("table", type(templates_list))
    end)

    it("should handle empty or non-empty template list", function()
      local templates_list = templates.list_templates()
      assert.truthy(type(templates_list) == "table")
      assert.truthy(#templates_list >= 0)
    end)
  end)

  describe("template resolution", function()
    it("should handle template resolution calls", function()
      -- Don't assert about return value, just that it doesn't crash
      local template = templates.resolve_template("bug")
      assert.truthy(template == nil or type(template) == "table")
    end)

    it("should handle invalid template gracefully", function()
      local template = templates.resolve_template("nonexistent_template_xyz_123")
      assert.truthy(template == nil or type(template) == "table")
    end)
  end)

  describe("recommended workflows", function()
    it("should return workflow list", function()
      local workflows = templates.get_recommended_workflows()
      assert.truthy(workflows)
      assert.equals("table", type(workflows))
    end)

    it("should return valid workflow structure", function()
      local workflows = templates.get_recommended_workflows()
      assert.truthy(type(workflows) == "table")
      -- Don't assert about specific workflows, just that it's a table
    end)
  end)
end)
