-- Test helper - provides mocks for Neovim API functions

-- Mock vim global for tests that don't require actual Neovim functionality
if not vim then
  vim = {
    notify = function(msg, level)
      print(msg)
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
    },
    fn = {
      shellescape = function(str)
        return "'" .. str:gsub("'", "'\\''") .. "'"
      end,
    },
    api = {
      nvim_create_buf = function() return 1 end,
      nvim_buf_set_option = function() end,
      nvim_buf_set_lines = function() end,
      nvim_get_current_buf = function() return 1 end,
      nvim_set_current_buf = function() end,
      nvim_buf_get_lines = function() return {} end,
      nvim_get_current_line = function() return "" end,
      nvim_get_option = function() return 80 end,
      nvim_set_option = function() end,
    },
    json = {
      decode = function(str)
        -- Simple JSON decoder
        if not str or str == "" then return nil end
        return require("dkjson").decode(str) or {}
      end,
      encode = function(obj)
        -- Simple JSON encoder
        return require("dkjson").encode(obj) or ""
      end,
    },
  }
end

return vim
