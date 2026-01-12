-- Beads CLI integration module
-- Provides Lua interfaces to Beads CLI commands

local M = {}

--- Check if beads is available
--- @return boolean True if 'bd' command is available
local function is_beads_available()
  local result = os.execute("which bd > /dev/null 2>&1")
  return result == 0 or result == true
end

--- Run a beads command and return parsed JSON output
--- @param cmd string Command to run (e.g., "ready", "show:123")
--- @param args table|nil Optional arguments to pass
--- @return table|nil Parsed JSON output or nil on error
--- @return string|nil Error message if command failed
local function run_command(cmd, args)
  if not is_beads_available() then
    return nil, "Beads CLI not found. Please install 'bd' or ensure it's in your PATH"
  end

  local full_cmd = string.format("bd %s", cmd)
  if args then
    for _, arg in ipairs(args) do
      full_cmd = full_cmd .. " " .. vim.fn.shellescape(arg)
    end
  end

  local handle = io.popen(full_cmd .. " 2>&1")
  if not handle then
    return nil, "Failed to run command: " .. cmd
  end

  local output = handle:read("*a")
  local exit_status = handle:close()

  if output == "" then
    if exit_status then
      return nil, "Command failed with exit code: " .. tostring(exit_status)
    end
    return nil, "No output from command"
  end

  -- Try to parse as JSON
  local ok, result = pcall(vim.json.decode, output)
  if ok then
    return result
  end

  -- Return raw output if not JSON
  return output
end

--- Get list of ready tasks
--- @return table|nil List of tasks
--- @return string|nil Error message
function M.ready()
  return run_command("ready")
end

--- Show details of a specific task
--- @param id string Task ID
--- @return table|nil Task details
--- @return string|nil Error message
function M.show(id)
  return run_command(string.format("show %s", id))
end

--- Create a new task
--- @param title string Task title
--- @param opts table|nil Optional fields (description, priority, etc.)
--- @return table|nil Created task
--- @return string|nil Error message
function M.create(title, opts)
  local args = { title }
  opts = opts or {}

  if opts.description then
    table.insert(args, "--description")
    table.insert(args, opts.description)
  end
  if opts.priority then
    table.insert(args, "--priority")
    table.insert(args, opts.priority)
  end

  return run_command("create", args)
end

--- Update a task
--- @param id string Task ID
--- @param opts table Fields to update (status, priority, description, etc.)
--- @return table|nil Updated task
--- @return string|nil Error message
function M.update(id, opts)
  local args = { id }
  opts = opts or {}

  if opts.status then
    table.insert(args, "--status")
    table.insert(args, opts.status)
  end
  if opts.priority then
    table.insert(args, "--priority")
    table.insert(args, opts.priority)
  end
  if opts.description then
    table.insert(args, "--description")
    table.insert(args, opts.description)
  end

  return run_command("update", args)
end

--- Close/complete a task
--- @param id string Task ID
--- @return table|nil Closed task
--- @return string|nil Error message
function M.close(id)
  return run_command(string.format("close %s", id))
end

--- Sync with remote
--- @return boolean True if successful
--- @return string|nil Error message
function M.sync()
  local output = run_command("sync")
  return output ~= nil, output
end

return M
