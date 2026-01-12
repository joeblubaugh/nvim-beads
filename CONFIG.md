# nvim-beads Configuration Guide

Complete reference for all configuration options in the nvim-beads plugin.

## Basic Setup

Initialize the plugin in your Neovim config:

```lua
require('beads').setup({
  -- configuration options here
})
```

## Core Options

### keymaps

**Type:** `boolean`
**Default:** `true`
**Description:** Enable default keymaps for common operations

```lua
require('beads').setup({
  keymaps = true  -- Set to false to disable all default keymaps
})
```

### auto_sync

**Type:** `boolean`
**Default:** `false`
**Description:** Enable periodic background synchronization with Beads daemon

```lua
require('beads').setup({
  auto_sync = true  -- Enable periodic background sync
})
```

**Note:** Disabled by default to prevent performance degradation. Enable only if your project has many tasks.

### sync_interval

**Type:** `number` (milliseconds)
**Default:** `10000` (10 seconds)
**Description:** Interval for periodic background syncs (only used if auto_sync is true)

```lua
require('beads').setup({
  sync_interval = 30000  -- Sync every 30 seconds
})
```

**Recommended values:**
- `5000` - Very responsive, may impact performance
- `10000` - Balanced (default)
- `30000` - Low frequency updates
- `60000` - Minimal overhead

### theme

**Type:** `string`
**Default:** `'dark'`
**Options:** `'dark'`, `'light'`
**Description:** Color theme for task list and UI elements

```lua
require('beads').setup({
  theme = 'dark'  -- or 'light'
})
```

### auto_theme

**Type:** `boolean`
**Default:** `false`
**Description:** Automatically detect theme from editor background

```lua
require('beads').setup({
  auto_theme = true  -- Auto-detect from vim.o.background
})
```

When enabled, the theme automatically switches based on your editor's `background` setting (dark/light).

## Advanced Configuration

### Cache Configuration

Control how the plugin caches task data:

```lua
local cli = require('beads.cli')

-- Disable caching entirely (always fetch fresh data)
cli.set_cache_enabled(false)

-- Set cache time-to-live
cli.set_cache_ttl(60000)  -- Cache for 60 seconds

-- Get cache statistics
local stats = cli.get_cache_stats()
print('Cache hit rate: ' .. stats.hit_rate)
print('Total requests: ' .. stats.total)
```

**Cache TTL Recommendations:**
- `30000` (30s) - Fast responses, frequently synced projects
- `60000` (1m) - Balanced, most projects
- `120000` (2m) - Large projects with slow CLI responses

### Status Line Integration

Configure task information in your statusline:

```lua
local sl = require('beads.statusline')

sl.setup({
  enabled = true,      -- Enable statusline display
  format = 'short',    -- Builtin format: 'short', 'indicator', 'priority', 'count'
})

-- Or build a custom format combining multiple displays
sl.setup({
  format = sl.build_format({
    'short',           -- "Beads:1/5"
    'indicator',       -- "[○2 ◐1 ✓2]"
    'priority',        -- "[P1:2 P2:3]"
  })
})

-- Custom format function
sl.setup({
  format = function(counts)
    return string.format("Tasks: %d open, %d in progress", counts.open, counts.in_progress)
  end
})
```

**Available built-in formats:**
- `count` - Just the number: `5`
- `short` - Abbreviated: `Beads:1/5`
- `indicator` - Status symbols: `[○2 ◐1 ✓2]`
- `priority` - Priority breakdown: `[P1:2 P2:3]`

### Theme Customization

Customize colors and create custom themes:

```lua
local theme = require('beads.theme')

-- Set individual colors
theme.set_color('P1', '#ff6b6b')        -- High priority color
theme.set_color('open', '#87ceeb')      -- Open task color
theme.set_color('in_progress', '#ffa500')
theme.set_color('closed', '#90ee90')
theme.apply_theme()

-- Register a custom theme
theme.register_theme('custom', {
  bg = '#1e1e1e',                  -- Background
  fg = '#e0e0e0',                  -- Foreground
  border = '#404040',              -- Border color
  title = '#64b5f6',               -- Title color
  accent = '#bb86fc',              -- Accent color

  -- Task status colors
  open = '#87ceeb',
  in_progress = '#ffa500',
  closed = '#90ee90',

  -- Priority colors
  P1 = '#ff6b6b',                  -- Highest
  P2 = '#ffd93d',                  -- Medium
  P3 = '#6bcf7f',                  -- Low
})

-- Switch to custom theme
theme.set_theme('custom')

-- Auto-detect from background
theme.auto_detect()
```

**Available highlight group keys:**
- `bg` - Default background
- `fg` - Default foreground text
- `border` - Window borders
- `title` - Section titles
- `accent` - UI accents
- `open` - Open task color
- `in_progress` - In-progress task color
- `closed` - Closed task color
- `P1`, `P2`, `P3` - Priority colors

### Sync Configuration

Control real-time sync behavior:

```lua
local sync = require('beads.sync')

-- Start periodic background sync
sync.start_auto_sync(10000)  -- Sync every 10 seconds

-- Stop background sync
sync.stop_auto_sync()

-- Manual sync
sync.sync()

-- Register callback on sync completion
sync.on_sync(function()
  print("Tasks synced!")
  -- Your code here
end)

-- Check sync status
if sync.is_syncing() then
  print("Sync in progress...")
end

-- Get time since last sync
local seconds = sync.time_since_last_sync()
```

### Template Configuration

Control template system behavior:

```lua
local templates = require('beads.templates')

-- Set custom variables for template substitution
templates.set_custom_vars({
  team = 'engineering',
  project = 'nvim-beads',
})

-- Ensure templates directory exists
templates.ensure_templates_dir()

-- Get all available templates
local list = templates.list_templates()

-- Load a specific template
local template = templates.load_template('bug')

-- Get template with defaults applied
local template = templates.get_template('feature')
```

## Complete Configuration Example

Here's a comprehensive configuration example combining multiple options:

```lua
-- Complete nvim-beads setup with all options
require('beads').setup({
  -- UI Options
  keymaps = true,
  theme = 'dark',
  auto_theme = true,

  -- Performance Options
  auto_sync = false,
  sync_interval = 30000,  -- 30 second sync interval
})

-- Cache Configuration
local cli = require('beads.cli')
cli.set_cache_ttl(120000)  -- 2 minute cache
cli.set_cache_enabled(true)

-- Statusline Configuration
local sl = require('beads.statusline')
sl.setup({
  enabled = true,
  format = sl.build_format({
    'short',      -- "Beads:1/5"
    'indicator',  -- "[○2 ◐1 ✓2]"
  })
})

-- Theme Customization
local theme = require('beads.theme')
theme.register_theme('custom-dark', {
  bg = '#0d1117',
  fg = '#c9d1d9',
  border = '#30363d',
  title = '#58a6ff',
  accent = '#79c0ff',
  open = '#79c0ff',
  in_progress = '#d29922',
  closed = '#3fb950',
  P1 = '#f85149',
  P2 = '#d29922',
  P3 = '#3fb950',
})
theme.set_theme('custom-dark')

-- Template Variables
local templates = require('beads.templates')
templates.set_custom_vars({
  team = 'your-team',
  project = 'your-project',
  environment = 'production',
})

-- Sync Configuration
local sync = require('beads.sync')
sync.on_sync(function()
  vim.notify('Tasks synced!', vim.log.levels.INFO)
end)

-- For debugging: enable verbose output
if vim.env.BEADS_DEBUG then
  vim.notify('Beads plugin loaded', vim.log.levels.INFO)
end
```

## Environment Variables

The plugin respects these environment variables:

| Variable | Purpose | Example |
|----------|---------|---------|
| `BD_ACTOR` | Author/actor name for operations | `BD_ACTOR=alice bd create "Task"` |
| `BEADS_DEBUG` | Enable debug output | `BEADS_DEBUG=1 nvim` |

## Performance Tuning

### For Large Projects (1000+ tasks)

```lua
require('beads').setup({
  auto_sync = false,    -- Disable background sync
  theme = 'dark',       -- Use simpler theme
  keymaps = true,
})

local cli = require('beads.cli')
cli.set_cache_ttl(180000)  -- Cache for 3 minutes
```

### For Small/Medium Projects

```lua
require('beads').setup({
  auto_sync = true,
  sync_interval = 10000,  -- Sync every 10 seconds
  theme = 'dark',
  auto_theme = true,      -- Enable auto theme detection
})

local cli = require('beads.cli')
cli.set_cache_ttl(30000)   -- Cache for 30 seconds
```

### For Development/Testing

```lua
require('beads').setup({
  keymaps = true,
})

local cli = require('beads.cli')
cli.set_cache_enabled(false)  -- Always fetch fresh data
```

## Troubleshooting Configuration

### Plugin not loading
- Check that `require('beads').setup()` is being called
- Verify beads is installed in `~/.config/nvim/plugins/` or via your plugin manager
- Check `:messages` for error details

### Keymaps not working
- Verify `keymaps = true` in setup
- Check for conflicting keymaps with `:verbose map <leader>bd`
- Try setting `keymaps = false` and define custom keymaps manually

### Slow performance
- Disable `auto_sync` or increase `sync_interval`
- Reduce cache TTL: `cli.set_cache_ttl(60000)`
- Disable statusline integration if not needed
- Try a simpler theme

### Tasks not syncing
- Check Beads is initialized: `bd list`
- Verify sync interval is reasonable (not too high)
- Manually sync with `:BeadsSync`
- Check for Beads daemon: `bd status`

## Command Reference

### CLI-based Configuration

Some settings can be configured via commands:

```vim
" Change theme at runtime
:BeadsTheme dark
:BeadsTheme light

" Set custom colors
:BeadsColor P1 #ff0000
:BeadsColor open #0066cc

" Set fuzzy finder backend
:BeadsSetFinder telescope
:BeadsSetFinder fzf_lua
:BeadsSetFinder builtin

" Toggle statusline
:BeadsStatuslineEnable
:BeadsStatuslineDisable
```

## Configuration Defaults Reference

This table shows all default values:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `keymaps` | bool | `true` | Enable default keymaps |
| `auto_sync` | bool | `false` | Enable periodic sync |
| `sync_interval` | number | `10000` | Sync interval (ms) |
| `theme` | string | `'dark'` | Color theme |
| `auto_theme` | bool | `false` | Auto-detect theme |

**Cache Defaults:**
- `enabled`: `true`
- `ttl`: `30000` (30 seconds)

**Statusline Defaults:**
- `enabled`: `false`
- `format`: `'short'`

## Getting Help

For more information:
- Check `:help beads` in Neovim
- See README.md for usage examples
- Check [Beads documentation](https://github.com/steveyegge/beads) for CLI options
- File an issue on GitHub if you find a bug
