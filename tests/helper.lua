-- Test helper - provides comprehensive mocks for Neovim API functions
-- This allows unit tests to run without requiring a Neovim instance

-- Mock vim global and its API for tests
if not vim then
  vim = {
    notify = function(msg, level)
      -- In tests, just print the message
      if os.getenv("VERBOSE_TESTS") then
        print("notify: " .. msg)
      end
    end,

    log = {
      levels = {
        DEBUG = 0,
        INFO = 1,
        WARN = 2,
        ERROR = 3,
      },
    },

    loop = {
      now = function()
        return os.time() * 1000  -- Return milliseconds
      end,
      sleep = function(ms)
        -- Mock sleep - just return immediately in tests
      end,
      new_timer = function()
        return {
          start = function() end,
          stop = function() end,
          close = function() end,
        }
      end,
      fs_event = function() end,
      fs_scandir = function() return nil end,
      fs_scandir_next = function() end,
      fs_stat = function() return { type = "file" } end,
    },

    fn = {
      shellescape = function(str)
        return "'" .. str:gsub("'", "'\\''") .. "'"
      end,
      environ = function()
        return os.environ()
      end,
      expand = function(str)
        -- Simple expansion of ~ and environment variables
        str = str:gsub("~", os.getenv("HOME") or "/home/user")
        return str
      end,
      fnamemodify = function(path, mods)
        if mods == ":h" then
          return path:match("(.*/)")  or "."
        elseif mods == ":t" then
          return path:match("([^/]*$)")
        end
        return path
      end,
      getcwd = function()
        return os.getenv("PWD") or "."
      end,
      mkdir = function(path, mode)
        os.execute("mkdir -p '" .. path .. "'")
        return 0
      end,
      readfile = function(path)
        local file = io.open(path, "r")
        if not file then return nil end
        local lines = {}
        for line in file:lines() do
          table.insert(lines, line)
        end
        file:close()
        return lines
      end,
      writefile = function(lines, path)
        local file = io.open(path, "w")
        if not file then return -1 end
        for _, line in ipairs(lines) do
          file:write(line .. "\n")
        end
        file:close()
        return 0
      end,
      reltime = function(start_time)
        -- Return a mock reltime - usually [seconds, microseconds]
        return {0, 0}
      end,
      reltimestr = function(reltime)
        -- Return formatted time string
        return "0.000"
      end,
      reltimeMs = function(reltime)
        -- Return milliseconds as a number
        return 0
      end,
    },

    api = {
      -- Buffer management
      nvim_create_buf = function(listed, scratch)
        return math.random(1, 10000)  -- Return a mock buffer number
      end,
      nvim_buf_set_option = function(buf, option, value) end,
      nvim_buf_set_lines = function(buf, start, finish, strict, lines) end,
      nvim_buf_get_lines = function(buf, start, finish, strict)
        return {}
      end,
      nvim_buf_line_count = function(buf)
        return 0
      end,
      nvim_get_current_buf = function()
        return 1
      end,
      nvim_set_current_buf = function(buf) end,

      -- Window management
      nvim_get_current_win = function()
        return 1
      end,
      nvim_win_is_valid = function(win)
        return true
      end,
      nvim_win_close = function(win, force) end,
      nvim_win_set_buf = function(win, buf) end,
      nvim_win_set_width = function(win, width) end,
      nvim_win_set_option = function(win, option, value) end,
      nvim_win_get_cursor = function(win)
        return {1, 0}  -- {line, column}
      end,
      nvim_win_set_cursor = function(win, pos) end,
      nvim_open_win = function(buf, enter, config)
        return math.random(1, 10000)  -- Return mock window ID
      end,
      nvim_get_current_line = function()
        return ""
      end,

      -- Autocmds and user commands
      nvim_create_augroup = function(name, opts) end,
      nvim_create_autocmd = function(event, opts) end,
      nvim_create_user_command = function(name, fn, opts) end,
    },

    json = {
      decode = function(str)
        -- Try to use cjson if available, otherwise basic parsing
        if not str or str == "" then return nil end

        -- Try to load cjson or dkjson
        local ok, module = pcall(require, "cjson")
        if ok then
          return module.decode(str)
        end

        -- Simple fallback - just return empty table for invalid JSON
        if str:sub(1, 1) == "{" or str:sub(1, 1) == "[" then
          return {}
        end
        return nil
      end,
      encode = function(obj)
        if not obj then return "null" end
        if type(obj) == "table" then
          return "{}"  -- Simplified
        end
        return tostring(obj)
      end,
    },

    -- Options
    o = {
      background = "dark",
      columns = 80,
      lines = 24,
    },

    -- Commands
    cmd = function(cmd) end,

    -- Scheduling
    schedule = function(fn)
      fn()  -- Execute immediately in tests
    end,
    schedule_wrap = function(fn)
      return function(...)
        local args = {...}
        vim.schedule(function() fn(unpack(args)) end)
      end
    end,

    -- Table utilities
    split = function(str, sep)
      local result = {}
      for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, part)
      end
      return result
    end,
    deepcopy = function(t)
      if type(t) ~= "table" then return t end
      local copy = {}
      for k, v in pairs(t) do
        copy[k] = vim.deepcopy(v)
      end
      return copy
    end,
    tbl_contains = function(t, item)
      for i, v in ipairs(t) do
        if v == item then return i end
      end
      return nil
    end,
    tbl_deep_extend = function(behavior, ...)
      local result = {}
      for _, t in ipairs({...}) do
        if type(t) == "table" then
          for k, v in pairs(t) do
            if type(v) == "table" and type(result[k]) == "table" and behavior == "force" then
              result[k] = vim.tbl_deep_extend(behavior, result[k], v)
            else
              result[k] = v
            end
          end
        end
      end
      return result
    end,
    tbl_extend = function(behavior, ...)
      local result = {}
      for _, t in ipairs({...}) do
        if type(t) == "table" then
          for k, v in pairs(t) do
            result[k] = v
          end
        end
      end
      return result
    end,

    -- UI
    ui = {
      input = function(opts, callback)
        callback("")  -- Return empty string in tests
      end,
      select = function(items, opts, callback)
        callback(nil)  -- Return nil selection in tests
      end,
    },
  }
end

return vim
