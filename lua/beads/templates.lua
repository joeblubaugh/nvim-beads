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

-- Template system for Beads task creation
local M = {}

local json = vim.json

-- Template structure
-- {
--   name: string,
--   description: string,
--   fields: {
--     priority: string (P1, P2, P3),
--     status: string (open, in_progress, closed),
--     title_template: string,
--     description_template: string,
--     checklist: table of strings
--   }
-- }

-- Get the templates directory path
local function get_templates_dir()
  local cwd = vim.fn.getcwd()
  return cwd .. "/.beads/templates"
end

--- Load a template from file
--- @param template_name string Name of the template (without extension)
--- @return table|nil Template data or nil if not found
function M.load_template(template_name)
  local templates_dir = get_templates_dir()

  -- Try JSON first
  local json_path = templates_dir .. "/" .. template_name .. ".json"
  local ok, content = pcall(vim.fn.readfile, json_path)
  if ok and content then
    local json_str = table.concat(content, "\n")
    local template = json.decode(json_str)
    if M.validate_template(template) then
      return template
    end
  end

  return nil
end

--- Validate template structure
--- @param template table Template data to validate
--- @return boolean True if valid
function M.validate_template(template)
  if not template or type(template) ~= "table" then
    return false
  end

  -- Check required fields
  if not template.name or not template.fields then
    return false
  end

  local fields = template.fields
  if not fields.title_template then
    return false
  end

  return true
end

--- Get all available templates
--- @return table List of template names
function M.list_templates()
  local templates_dir = get_templates_dir()

  -- Check if directory exists
  local stat = vim.loop.fs_stat(templates_dir)
  if not stat or stat.type ~= "directory" then
    return {}
  end

  local templates = {}
  local scan_dir = vim.loop.fs_scandir(templates_dir)
  if not scan_dir then
    return {}
  end

  while true do
    local name, typ = vim.loop.fs_scandir_next(scan_dir)
    if not name then
      break
    end

    if typ == "file" and name:match("%.json$") then
      local template_name = name:gsub("%.json$", "")
      table.insert(templates, template_name)
    end
  end

  return templates
end

--- Create template directory if it doesn't exist
--- @return boolean True if successful
function M.ensure_templates_dir()
  local templates_dir = get_templates_dir()

  local stat = vim.loop.fs_stat(templates_dir)
  if stat and stat.type == "directory" then
    return true
  end

  -- Create directory recursively
  local ok = vim.fn.mkdir(templates_dir, "p")
  return ok == 1
end

--- Get template data with default values applied
--- @param template_name string Name of the template
--- @return table|nil Resolved template data or nil if not found
function M.get_template(template_name)
  local template = M.load_template(template_name)
  if not template then
    return nil
  end

  -- Apply defaults
  if not template.fields.priority then
    template.fields.priority = "P2"
  end

  if not template.fields.status then
    template.fields.status = "open"
  end

  return template
end

--- Create a new template
--- @param name string Template name
--- @param fields table Template fields
--- @return boolean True if successful
function M.save_template(name, fields)
  if not M.ensure_templates_dir() then
    vim.notify("Failed to create templates directory", vim.log.levels.ERROR)
    return false
  end

  local template = {
    name = name,
    description = fields.description or "",
    fields = fields
  }

  if not M.validate_template(template) then
    vim.notify("Invalid template structure", vim.log.levels.ERROR)
    return false
  end

  local templates_dir = get_templates_dir()
  local path = templates_dir .. "/" .. name .. ".json"

  local json_str = json.encode(template)
  local ok = vim.fn.writefile(vim.split(json_str, "\n"), path)

  if ok == 0 then
    return true
  else
    vim.notify("Failed to save template: " .. name, vim.log.levels.ERROR)
    return false
  end
end

return M
