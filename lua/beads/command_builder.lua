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

-- Command builder patterns for Beads commands

local M = {}

--- Build simple UI command (validate -> call ui function)
--- @param ui_func function UI function to call
--- @param validator function Optional validation function (args -> result)
--- @return function Command handler
function M.ui_command(ui_func, validator)
  return function(opts)
    if validator then
      local result = validator(opts)
      if not result then return end
      ui_func(result)
    else
      ui_func()
    end
  end
end

--- Build config command (get config -> modify -> save -> notify -> refresh)
--- @param config_key string Config key to modify
--- @param transformer function Function to transform value (opts, config) -> (value, notify_msg)
--- @return function Command handler
function M.config_command(config_key, transformer)
  return function(opts)
    local beads = require("beads")
    local ui = require("beads.ui")
    local config = beads.get_config()

    local value, notify_msg = transformer(opts, config)
    if not value then return end

    config[config_key] = value
    beads.save_sidebar_config()
    vim.notify(notify_msg, vim.log.levels.INFO)
    ui.refresh_task_list()
  end
end

--- Build template command (validate template -> create from template)
--- @param template_name string Template name
--- @return function Command handler
function M.template_command(template_name)
  return function(opts)
    local templates = require("beads.templates")
    local ui = require("beads.ui")

    local template = templates.resolve_template(template_name)
    if not template then
      vim.notify("Template not found: " .. template_name, vim.log.levels.ERROR)
      return
    end
    ui.create_task_from_template(template)
  end
end

--- Build module command (load module -> call function -> notify)
--- @param module_path string Module path to require
--- @param func_name string Function name in module
--- @param validator function Optional validator function
--- @param success_msg_formatter function Function to format success message
--- @return function Command handler
function M.module_command(module_path, func_name, validator, success_msg_formatter)
  return function(opts)
    local module = require(module_path)
    local func = module[func_name]
    if not func then
      vim.notify("Function not found: " .. func_name, vim.log.levels.ERROR)
      return
    end

    local value
    if validator then
      value = validator(opts)
      if not value then return end
    else
      value = opts.args
    end

    func(value)

    if success_msg_formatter then
      local msg = success_msg_formatter(value)
      vim.notify(msg, vim.log.levels.INFO)
    end
  end
end

return M
