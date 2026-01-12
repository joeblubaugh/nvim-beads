# nvim-beads

A Neovim plugin for task tracking that integrates with [Beads](https://github.com/steveyegge/beads) - an AI-native, git-based issue tracking system.

## What is nvim-beads?

**nvim-beads** brings task tracking directly into your editor. Keep all your project tasks stored in git alongside your code—no external services, no account required. Manage tasks, prioritize work, and track progress without leaving Neovim.

### Why Use Beads?

- **Git-native**: Issues stored in `.beads/` directory, synced with git
- **Offline-first**: Works without external services or accounts
- **AI-friendly**: CLI-first design optimized for AI coding agents
- **Lightweight**: SQLite backend with JSONL export
- **Collaborative**: Automatic conflict resolution for shared workflows

## Installation

### Prerequisites

- Neovim (v0.7+)
- Beads CLI (`bd`) - [Install Beads](https://github.com/steveyegge/beads)

### Setup with your plugin manager

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'joeblubaugh/nvim-beads',
  config = function()
    require('beads').setup()
  end
}
```

Or [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'joeblubaugh/nvim-beads',
  config = function()
    require('beads').setup()
  end
}
```

## Quick Start

### Initialize Beads in your project

```bash
cd your-project
bd onboard
```

### Basic Neovim Commands

```vim
" Show all open tasks
:Beads

" Create a new task
:BeadsCreate New feature: add dark mode

" View task details
:BeadsShow nvim-beads-abc

" Create a task from a template
:BeadsCreateBug        " Quick bug report
:BeadsCreateFeature    " New feature request
:BeadsCreateDoc        " Documentation task
:BeadsCreateChore      " Maintenance task

" Update a task
:BeadsUpdate nvim-beads-abc status in_progress
:BeadsUpdate nvim-beads-abc priority P1

" Close a completed task
:BeadsClose nvim-beads-abc

" Sync with git
:BeadsSync
```

### Using Keymaps

Default keymaps (when enabled in setup):

| Keymap | Action |
|--------|--------|
| `<leader>bd` | Show task list |
| `<leader>bc` | Create new task |
| `<leader>bs` | Sync tasks |
| `<leader>br` | Refresh task list |
| `<leader>bt` | Find task with fuzzy finder |
| `<leader>bS` | Find and update task status |
| `<leader>bP` | Find and update task priority |
| `<leader>bf` | Filter tasks |
| `<leader>bF` | Clear filters |

In the task list window:
- `q` - Close window
- `<CR>` - View task details
- `r` - Refresh list
- `f` - Filter tasks
- `c` - Clear filters

## Core Features

### Task Management

Create, update, and track tasks with full details:

```vim
" Create tasks with description and priority
:BeadsCreate Fix login bug
:BeadsCreate --priority P1 Critical security issue

" Update any task field
:BeadsUpdate nvim-beads-123 status closed
:BeadsUpdate nvim-beads-123 priority P2
:BeadsUpdate nvim-beads-123 description Updated task details
```

### Task Templates

Create tasks quickly with templates for common patterns:

```vim
" Create from built-in templates
:BeadsCreateBug       " Bug report template
:BeadsCreateFeature   " Feature request template
:BeadsCreateDoc       " Documentation template
:BeadsCreateChore     " Maintenance template

" Create from any template
:BeadsCreateFromTemplate bug
:BeadsCreateFromTemplate feature

" See available templates
:BeadsListTemplates

" View recommended workflows
:BeadsWorkflows
```

**Built-in templates include:**
- **bug** - Bug reports with priority and reproduction steps
- **feature** - Feature requests with requirements and acceptance criteria
- **documentation** - Documentation updates with sections
- **chore** - Maintenance tasks with scope and verification steps

### Filtering Tasks

Filter the task list by status, priority, or assignee:

```vim
" Filter by single criterion
:BeadsFilter priority:P1
:BeadsFilter status:open
:BeadsFilter assignee:alice

" Combine multiple filters (AND logic)
:BeadsFilter priority:P1,status:open
:BeadsFilter status:open,assignee:alice

" Clear filters
:BeadsClearFilters

" Filter in the task list window with 'f' key
```

**Supported Filters:**
- `priority` - P1, P2, P3
- `status` - open, in_progress, closed
- `assignee` - User name

### Fuzzy Finder Integration

Quickly find and work with tasks using your preferred fuzzy finder:

```vim
" Find a task by name, ID, or content
:BeadsFindTask

" Find and change task status
:BeadsFindStatus

" Find and change task priority
:BeadsFindPriority

" Switch between finders (telescope, fzf_lua, builtin)
:BeadsSetFinder telescope
```

Supports:
- **telescope.nvim** - Full-featured picker (if installed)
- **fzf-lua** - Command-line style finder (if installed)
- **builtin** - Native Neovim selection (always available)

### Statusline Integration

Display task information in your statusline:

```vim
" Show statusline format
:BeadsStatusline

" Enable/disable statusline
:BeadsStatuslineEnable
:BeadsStatuslineDisable
```

Add to your Neovim config:

```lua
require('beads').setup()
local sl = require('beads.statusline')
sl.setup({ enabled = true })
```

### Themes and Colors

Customize the appearance of the task list and UI:

```vim
" Switch themes
:BeadsTheme dark
:BeadsTheme light

" Set custom colors
:BeadsColor P1 #ff0000
:BeadsColor open #0066cc

" Auto-detect from editor background
:BeadsThemeAuto
```

Configure in setup:

```lua
require('beads').setup({
  theme = 'dark',       -- 'dark' or 'light'
  auto_theme = true,    -- Auto-detect from vim.o.background
})
```

## Configuration

### Basic Setup

```lua
require('beads').setup({
  keymaps = true,       -- Enable default keymaps
  auto_sync = false,    -- Periodic sync (disabled by default)
  sync_interval = 10000,-- Sync interval in milliseconds
  theme = 'dark',       -- 'dark' or 'light'
  auto_theme = false,   -- Auto-detect theme
})
```

### Available Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `keymaps` | boolean | `true` | Enable default keymaps |
| `auto_sync` | boolean | `false` | Enable periodic background sync |
| `sync_interval` | number | `10000` | Sync interval (milliseconds) |
| `theme` | string | `'dark'` | Color theme ('dark', 'light') |
| `auto_theme` | boolean | `false` | Auto-detect theme from background |

### Cache Configuration

For performance optimization:

```lua
local cli = require('beads.cli')

-- Disable caching (always fetch fresh data)
cli.set_cache_enabled(false)

-- Set cache time-to-live (milliseconds)
cli.set_cache_ttl(60000)  -- 1 minute

-- View cache statistics
local stats = cli.get_cache_stats()
print(stats.hit_rate)  -- "87.5%"
```

### Custom Colors and Themes

Define custom color schemes:

```lua
local theme = require('beads.theme')

-- Set individual colors
theme.set_color('P1', '#ff6b6b')
theme.set_color('open', '#87ceeb')
theme.apply_theme()

-- Register custom theme
theme.register_theme('custom', {
  bg = '#1e1e1e',
  fg = '#e0e0e0',
  open = '#87ceeb',
  in_progress = '#ffa500',
  closed = '#90ee90',
  P1 = '#ff6b6b',
  P2 = '#ffd93d',
  P3 = '#6bcf7f',
})
theme.set_theme('custom')
```

## Workflow Examples

### Daily Workflow

1. **Morning standup**
   ```vim
   :Beads
   " Review open and in_progress tasks
   ```

2. **Start new work**
   ```vim
   :BeadsFindTask
   " Select task to work on
   :BeadsUpdate nvim-beads-abc status in_progress
   ```

3. **During work**
   - Switch back to task list with `<leader>bd`
   - Filter by priority: `:BeadsFilter priority:P1`
   - Quick fuzzy search: `<leader>bt`

4. **Finishing up**
   ```vim
   :BeadsClose nvim-beads-abc
   :BeadsSync
   ```

### Creating Issues

**Quick task creation:**
```vim
:BeadsCreate Fix typo in docs
```

**Using templates (recommended):**
```vim
:BeadsCreateBug         " Bug report with full details
:BeadsCreateFeature     " Feature request with requirements
```

**Creating from template interactively:**
```vim
:BeadsCreateFromTemplate
" Prompts to select template and enter details
```

### Filtering Workflow

```vim
" Show only high-priority open tasks
:BeadsFilter priority:P1,status:open

" Show tasks assigned to you
:BeadsFilter assignee:your-name

" Clear and start over
:BeadsClearFilters
```

## Troubleshooting

### "Beads CLI not found"

Make sure the `bd` command is installed and in your PATH:

```bash
which bd
bd --version
```

If not found, [install Beads](https://github.com/steveyegge/beads).

### Tasks not showing

1. Make sure you're in a Beads project: `ls .beads/`
2. Initialize Beads if needed: `bd onboard`
3. Refresh the plugin: `:BeadsRefresh`
4. Check for errors: `:messages`

### Performance issues

If the plugin feels slow:

1. Disable auto-sync: Set `auto_sync = false` in setup
2. Increase cache TTL: `cli.set_cache_ttl(120000)` for 2 minutes
3. Reduce statusline updates: Disable statusline or increase sync interval

## Performance

The plugin uses caching to minimize CLI calls:

- **Default cache TTL**: 30 seconds
- **Automatic invalidation**: On create, update, or close
- **Async operations**: All CLI operations are non-blocking
- **Minimal overhead**: Efficiently handles hundreds of tasks

## Getting Help

- **Plugin Documentation**: `:help beads`
- **Beads Documentation**: [github.com/steveyegge/beads](https://github.com/steveyegge/beads)
- **Neovim Docs**: `:help plugin`

---

# For Developers

## Plugin Architecture

The plugin is organized into focused modules:

| Module | Purpose |
|--------|---------|
| `init.lua` | Plugin initialization and configuration |
| `cli.lua` | Beads CLI command wrapper and caching |
| `ui.lua` | UI components and task display |
| `commands.lua` | Neovim command definitions |
| `keymaps.lua` | Default keymap setup |
| `filters.lua` | Task filtering logic |
| `fuzzy.lua` | Fuzzy finder abstraction layer |
| `fuzzy_*.lua` | Finder implementations (telescope, fzf, builtin) |
| `statusline.lua` | Statusline/tabline integration |
| `theme.lua` | Theme and highlight customization |
| `sync.lua` | Real-time sync with Beads daemon |
| `templates.lua` | Template system for tasks |

### Entry Point

- **`plugin/beads.lua`** - Loaded automatically on Neovim startup

## Project Structure

```
nvim-beads/
├── plugin/
│   └── beads.lua           # Plugin entry point
├── lua/beads/
│   ├── init.lua            # Main module
│   ├── cli.lua             # CLI wrapper
│   ├── ui.lua              # UI components
│   ├── commands.lua        # Neovim commands
│   ├── keymaps.lua         # Default keymaps
│   ├── filters.lua         # Filtering logic
│   ├── fuzzy.lua           # Fuzzy finder abstraction
│   ├── fuzzy_telescope.lua # Telescope implementation
│   ├── fuzzy_fzf.lua       # fzf implementation
│   ├── fuzzy_builtin.lua   # Built-in implementation
│   ├── statusline.lua      # Statusline integration
│   ├── theme.lua           # Theme system
│   ├── sync.lua            # Sync module
│   └── templates.lua       # Template system
├── .beads/
│   ├── config.yaml         # Beads configuration
│   ├── beads.db            # Task database
│   └── issues.jsonl        # Task storage
├── doc/
│   └── beads.txt           # Help documentation
└── README.md               # This file
```

## Development Guide

### Prerequisites

- Neovim 0.7+
- Lua 5.1+
- Beads CLI (`bd`)

### Getting Started with Development

1. Clone and navigate to the repository
2. Install Beads if not already installed
3. Initialize the beads project: `bd onboard`
4. Use the plugin by pointing Neovim to this directory

### Testing

Tests are located in `tests/` directory using Lua testing frameworks.

```bash
# Run tests with Neovim
nvim --noplugin -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
```

### Key Implementation Notes

**CLI Integration:**
- All `bd` commands wrapped in `lua/beads/cli.lua`
- Responses automatically parsed as JSON
- Built-in caching with configurable TTL
- Automatic cache invalidation on mutations

**Async Operations:**
- All blocking calls use `vim.schedule()` for non-blocking execution
- CLI operations return (result, error) tuples
- Progress tracking for long-running operations

**UI Components:**
- Floating window with proper styling
- Highlight groups for theming
- Filter state preservation
- Keyboard navigation and selection

### Adding New Features

To add a new command or feature:

1. **Add CLI wrapper** (if needed) in `lua/beads/cli.lua`
2. **Add UI function** in `lua/beads/ui.lua`
3. **Add Neovim command** in `lua/beads/commands.lua`
4. **Add keymaps** in `lua/beads/keymaps.lua` (optional)
5. **Add tests** in `tests/` directory
6. **Track with beads**: `bd create "Feature: ..." `

## Beads Configuration

The Beads system is configured in `.beads/config.yaml`:

- **Issue tracking**: Create, update, and close issues locally
- **Git sync**: Automatic synchronization with git branches
- **JSONL storage**: Issues tracked in human-readable JSON format
- **Merge drivers**: Intelligent conflict resolution for shared workflows

See [Beads Documentation](https://github.com/steveyegge/beads) for full details.

## Resources

- [Beads Documentation](https://github.com/steveyegge/beads)
- [Neovim Plugin Development Guide](https://neovim.io/doc/user/plugin/)
- [Vim Script Language](https://neovim.io/doc/user/userfunc.html)
- [Lua in Neovim](https://neovim.io/doc/user/lua.html)

## Contributing

This plugin is open to contributions. Please:

1. Fork the repository
2. Create a feature branch
3. Track your work with `bd create`
4. Submit a pull request with closed issues

## License

TBD

## Changelog

For a detailed list of changes, see the Beads issues and commits in this repository.
