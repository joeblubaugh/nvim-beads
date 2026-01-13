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

-- Neovim commands for beads plugin

local M = {}
local cli = require("beads.cli")
local ui = require("beads.ui")
local validation = require("beads.validation")
local builder = require("beads.command_builder")

--- Setup Neovim commands
function M.setup()
  -- Main beads command - show task list
  vim.api.nvim_create_user_command("Beads", function(opts)
    ui.show_task_list()
  end, { desc = "Show Beads task list" })

  -- Create new task
  vim.api.nvim_create_user_command("BeadsCreate", function(opts)
    local title = opts.args
    if title == "" then
      -- No arguments: open interactive editor
      ui.create_task()
    else
      -- Arguments provided: use as title
      ui.create_task(title)
    end
  end, {
    desc = "Create a new Beads task (with optional title)",
    nargs = "*",
  })

  -- Show task details
  vim.api.nvim_create_user_command("BeadsShow", function(opts)
    local id = validation.require_id(opts)
    if id then ui.show_task_detail(id) end
  end, {
    desc = "Show details of a Beads task",
    nargs = 1,
  })

  -- Update task
  vim.api.nvim_create_user_command("BeadsUpdate", function(opts)
    local args = validation.require_min_args(opts, 2, ":BeadsUpdate <id> <field> <value>")
    if args then
      local id = args[1]
      local field = args[2]
      local value = table.concat(args, " ", 3)
      ui.update_task(id, field, value)
    end
  end, {
    desc = "Update a Beads task",
    nargs = "+",
  })

  -- Close task
  vim.api.nvim_create_user_command("BeadsClose", function(opts)
    local id = validation.require_id(opts)
    if id then ui.close_task(id) end
  end, {
    desc = "Close a Beads task",
    nargs = 1,
  })

  -- Sync with remote
  vim.api.nvim_create_user_command("BeadsSync", function(opts)
    ui.sync()
  end, { desc = "Sync with Beads remote" })

  -- Refresh task list
  vim.api.nvim_create_user_command("BeadsRefresh", function(opts)
    ui.refresh_task_list()
  end, { desc = "Refresh Beads task list" })

  -- Filter tasks
  vim.api.nvim_create_user_command("BeadsFilter", function(opts)
    local filter_str = validation.require_arg(opts, ":BeadsFilter priority:P1,status:open,assignee:name")
    if filter_str then
      ui.apply_filter_string(filter_str)
      ui.refresh_task_list()
    end
  end, {
    desc = "Filter tasks by priority, status, or assignee",
    nargs = "+",
  })

  -- Clear filters
  vim.api.nvim_create_user_command("BeadsClearFilters", function(opts)
    ui.clear_filters()
    ui.refresh_task_list()
    vim.notify("Filters cleared", vim.log.levels.INFO)
  end, {
    desc = "Clear all active filters",
  })

  -- Find and select task with fuzzy finder
  vim.api.nvim_create_user_command("BeadsFindTask", function(opts)
    ui.find_task()
  end, { desc = "Find and select a task using fuzzy finder" })

  -- Find and update task status with fuzzy finder
  vim.api.nvim_create_user_command("BeadsFindStatus", function(opts)
    ui.find_task_status()
  end, { desc = "Find and update task status with fuzzy finder" })

  -- Find and update task priority with fuzzy finder
  vim.api.nvim_create_user_command("BeadsFindPriority", function(opts)
    ui.find_task_priority()
  end, { desc = "Find and update task priority with fuzzy finder" })

  -- Set fuzzy finder backend
  vim.api.nvim_create_user_command("BeadsSetFinder", function(opts)
    local backend = validation.require_arg(opts, ":BeadsSetFinder telescope|fzf_lua|builtin")
    if backend then
      local fuzzy = require("beads.fuzzy")
      fuzzy.set_finder(backend)
      vim.notify("Fuzzy finder backend set to: " .. backend, vim.log.levels.INFO)
    end
  end, {
    desc = "Set preferred fuzzy finder backend (telescope, fzf_lua, or builtin)",
    nargs = 1,
  })

  -- Setup statusline integration
  vim.api.nvim_create_user_command("BeadsStatusline", function(opts)
    local statusline = require("beads.statusline")
    local component = statusline.register_statusline_component()
    vim.notify("Beads statusline component: " .. component, vim.log.levels.INFO)
    vim.notify("Add to your statusline setting: " .. component, vim.log.levels.INFO)
  end, { desc = "Show beads statusline component for use in statusline setting" })

  -- Enable statusline for current window
  vim.api.nvim_create_user_command("BeadsStatuslineEnable", function(opts)
    local statusline = require("beads.statusline")
    statusline.setup({ enabled = true })
    vim.notify("Beads statusline enabled", vim.log.levels.INFO)
  end, { desc = "Enable beads statusline integration" })

  -- Disable statusline for current window
  vim.api.nvim_create_user_command("BeadsStatuslineDisable", function(opts)
    local statusline = require("beads.statusline")
    statusline.setup({ enabled = false })
    vim.notify("Beads statusline disabled", vim.log.levels.INFO)
  end, { desc = "Disable beads statusline integration" })

  -- Set theme
  vim.api.nvim_create_user_command("BeadsTheme", function(opts)
    local theme_name = opts.args
    if theme_name == "" then
      local theme = require("beads.theme")
      vim.notify("Available themes: " .. table.concat(theme.get_available_themes(), ", "), vim.log.levels.INFO)
      return
    end
    local theme = require("beads.theme")
    theme.set_theme(theme_name)
    vim.notify("Theme set to: " .. theme_name, vim.log.levels.INFO)
  end, {
    desc = "Set beads theme (dark, light, or custom)",
    nargs = "?",
  })

  -- Set custom color
  vim.api.nvim_create_user_command("BeadsColor", function(opts)
    local args = validation.require_min_args(opts, 2, ":BeadsColor <key> <hex_color>")
    if args then
      local key = args[1]
      local color = args[2]
      local theme = require("beads.theme")
      theme.set_color(key, color)
      theme.apply_theme()
      vim.notify("Color set: " .. key .. " = " .. color, vim.log.levels.INFO)
    end
  end, {
    desc = "Set custom color for beads theme",
    nargs = "+",
  })

  -- Toggle auto theme
  vim.api.nvim_create_user_command("BeadsThemeAuto", function(opts)
    local theme = require("beads.theme")
    theme.auto_detect()
    vim.notify("Theme auto-detected from background: " .. theme.get_current_theme(), vim.log.levels.INFO)
  end, { desc = "Auto-detect theme from background setting" })

  -- List available templates
  vim.api.nvim_create_user_command("BeadsListTemplates", function(opts)
    local template_list = validate_template_list()
    if template_list then
      vim.notify("Available templates:\n- " .. table.concat(template_list, "\n- "), vim.log.levels.INFO)
    end
  end, { desc = "List available task templates" })

  -- Show recommended workflows
  vim.api.nvim_create_user_command("BeadsWorkflows", function(opts)
    local templates = require("beads.templates")
    local workflows = templates.get_recommended_workflows()

    local lines = { "Available Workflows:", "" }
    for _, wf in ipairs(workflows) do
      table.insert(lines, "• " .. wf.name)
      table.insert(lines, "  " .. wf.description)
      table.insert(lines, "  Templates: " .. table.concat(wf.templates, ", "))
      table.insert(lines, "")
    end

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Show recommended workflow templates" })

  -- Helper function to validate template list
  local function validate_template_list()
    local templates = require("beads.templates")
    local template_list = templates.list_templates()
    return validation.require_non_empty_list(template_list, "No templates found") and template_list or nil
  end

  -- Helper function for template-based task creation
  local function create_task_from_template(template_name)
    local templates = require("beads.templates")
    local template = templates.resolve_template(template_name)
    if not template then
      vim.notify("Template not found: " .. template_name, vim.log.levels.ERROR)
      return
    end
    ui.create_task_from_template(template)
  end

  -- Create task from template
  vim.api.nvim_create_user_command("BeadsCreateFromTemplate", function(opts)
    local template_list = validate_template_list()
    if not template_list then return end

    -- If template specified as argument, use it
    if opts.args ~= "" then
      create_task_from_template(opts.args)
      return
    end

    -- Otherwise, show picker if fuzzy finder available
    local fuzzy = require("beads.fuzzy")
    if fuzzy.is_available() then
      fuzzy.pick_template(function(selected_template)
        if selected_template then
          create_task_from_template(selected_template)
        end
      end)
    else
      -- Fallback: show template list and prompt for input
      vim.notify("Available templates: " .. table.concat(template_list, ", "), vim.log.levels.INFO)
      vim.ui.input({ prompt = "Enter template name: " }, function(choice)
        if choice and choice ~= "" then
          create_task_from_template(choice)
        end
      end)
    end
  end, {
    desc = "Create a new task from a template",
    nargs = "?",
  })

  -- Shortcut commands for common templates
  vim.api.nvim_create_user_command("BeadsCreateBug", function(opts)
    create_task_from_template("bug")
  end, { desc = "Create a new bug report task" })

  vim.api.nvim_create_user_command("BeadsCreateFeature", function(opts)
    create_task_from_template("feature")
  end, { desc = "Create a new feature request task" })

  vim.api.nvim_create_user_command("BeadsCreateDoc", function(opts)
    create_task_from_template("documentation")
  end, { desc = "Create a new documentation task" })

  vim.api.nvim_create_user_command("BeadsCreateChore", function(opts)
    create_task_from_template("chore")
  end, { desc = "Create a new maintenance/chore task" })

  -- Delete task
  vim.api.nvim_create_user_command("BeadsDelete", function(opts)
    local id = validation.require_id(opts)
    if id then ui.delete_task(id) end
  end, {
    desc = "Delete a Beads task",
    nargs = 1,
  })

  -- Create epic
  vim.api.nvim_create_user_command("BeadsCreateEpic", function(opts)
    create_task_from_template("epic")
  end, { desc = "Create a new epic" })

  -- Show children of an epic
  vim.api.nvim_create_user_command("BeadsShowChildren", function(opts)
    local parent_id = validation.require_id(opts, "Parent task ID")
    if parent_id then ui.show_task_children(parent_id) end
  end, {
    desc = "Show child issues of an epic",
    nargs = 1,
  })

  -- Create child issue
  vim.api.nvim_create_user_command("BeadsCreateChild", function(opts)
    local args = validation.require_min_args(opts, 1, ":BeadsCreateChild <parent_id> [title]")
    if args then
      local parent_id = args[1]
      local title = table.concat(args, " ", 2) or ""
      ui.create_child_task(parent_id, title)
    end
  end, {
    desc = "Create a child issue under a parent epic",
    nargs = "+",
  })

  -- Toggle sidebar mode
  vim.api.nvim_create_user_command("BeadsSidebar", function(opts)
    local beads = require("beads")
    local config = beads.get_config()
    if opts.args == "on" then
      config.sidebar_enabled = true
      vim.notify("Beads sidebar enabled", vim.log.levels.INFO)
    elseif opts.args == "off" then
      config.sidebar_enabled = false
      vim.notify("Beads sidebar disabled", vim.log.levels.INFO)
    else
      config.sidebar_enabled = not config.sidebar_enabled
      local status = config.sidebar_enabled and "enabled" or "disabled"
      vim.notify("Beads sidebar " .. status, vim.log.levels.INFO)
    end
    beads.save_sidebar_config()
    ui.refresh_task_list()
  end, {
    desc = "Toggle sidebar mode or set on/off",
    nargs = "?",
  })

  -- Set sidebar position
  vim.api.nvim_create_user_command("BeadsSidebarPosition", function(opts)
    local position = validation.require_arg(opts, ":BeadsSidebarPosition left|right")
    if position and validation.validate_enum(position, { "left", "right" }, "Position") then
      local beads = require("beads")
      local config = beads.get_config()
      config.sidebar_position = position
      beads.save_sidebar_config()
      vim.notify("Sidebar position set to: " .. position, vim.log.levels.INFO)
      ui.refresh_task_list()
    end
  end, {
    desc = "Set sidebar position (left or right)",
    nargs = 1,
  })

  -- Set sidebar width
  vim.api.nvim_create_user_command("BeadsSidebarWidth", function(opts)
    local width = tonumber(opts.args)
    if validation.validate_range(width, 20, 120, "Width") then
      local beads = require("beads")
      local config = beads.get_config()
      config.sidebar_width = width
      beads.save_sidebar_config()
      vim.notify("Sidebar width set to: " .. width, vim.log.levels.INFO)
      ui.refresh_task_list()
    end
  end, {
    desc = "Set sidebar width (20-120 columns)",
    nargs = 1,
  })
end

-- Initialize commands on load
M.setup()

return M
