# nvim-beads

A Neovim plugin for task tracking that integrates with [Beads](https://github.com/steveyegge/beads) - an AI-native, git-based issue tracking system.

## Overview

**nvim-beads** demonstrates how to build a Neovim plugin that leverages Beads for project management. Instead of relying on external web-based issue trackers, Beads keeps all task tracking directly in your git repository alongside your code.

### Why Beads?

- **Git-native**: Issues stored in `.beads/` directory, synced with git
- **AI-friendly**: CLI-first design optimized for AI coding agents
- **Offline-first**: Works without external services or accounts
- **Collaborative**: Automatic conflict resolution for shared workflows
- **Lightweight**: SQLite backend with JSONL export

## Project Status

This is a freshly initialized project with:
- ✅ Beads infrastructure configured
- ✅ Agent workflow documentation
- ⏳ Neovim plugin code (coming soon)

## Current Structure

```
nvim-beads/
├── .beads/              # Beads issue tracking system
│   ├── beads.db        # SQLite database
│   ├── config.yaml     # Beads configuration
│   └── issues.jsonl    # Issue storage (git-tracked)
├── AGENTS.md           # AI agent workflow instructions
└── README.md           # This file
```

## Getting Started

### Prerequisites

- Neovim (development version)
- Beads CLI (`bd`)

### Installation

```bash
# Clone the repository
git clone https://github.com/joeblubaugh/nvim-beads.git
cd nvim-beads

# Initialize Beads (one-time setup)
bd onboard
```

### Basic Commands

```bash
# Find available work
bd ready

# View issue details
bd show <id>

# Claim work (mark in progress)
bd update <id> --status in_progress

# Complete work
bd close <id>

# Sync with git
bd sync
```

## Workflow

### Starting Work

1. Find available tasks: `bd ready`
2. Claim a task: `bd update <id> --status in_progress`
3. Work on the task in Neovim
4. Track progress using issue comments

### Finishing Work

1. Ensure all code is committed: `git status`
2. Run quality checks (tests, linters, etc.)
3. Close completed issues: `bd close <id>`
4. Sync and push: `bd sync && git push`

## Integration with Agents

This project is designed to work seamlessly with AI coding agents. See [AGENTS.md](AGENTS.md) for detailed workflow instructions, including the mandatory session completion checklist.

## Beads Configuration

The Beads system is configured in `.beads/config.yaml`. Key features:

- **Issue tracking**: Create, update, and close issues locally
- **Git sync**: Automatic synchronization with git branches
- **JSONL storage**: Issues tracked in human-readable JSON format
- **Merge drivers**: Intelligent conflict resolution for shared workflows

## Usage Examples

### In Neovim

```lua
-- Initialize with defaults
require('beads').setup()

-- Or with custom configuration
require('beads').setup({
  keymaps = true,
  auto_sync = true,
  sync_interval = 5000
})
```

### Commands

```vim
" Show task list
:Beads

" Create a new task
:BeadsCreate Implement new feature

" View task details
:BeadsShow nvim-beads-abc

" Update task status
:BeadsUpdate nvim-beads-abc status in_progress

" Close a completed task
:BeadsClose nvim-beads-abc

" Sync with remote
:BeadsSync

" Filter tasks (examples)
:BeadsFilter priority:P1
:BeadsFilter status:open,in_progress
:BeadsFilter priority:P1,status:open,assignee:alice

" Clear all filters
:BeadsClearFilters
```

### Filtering

Advanced filtering is supported with multiple filter types:

**Filter Syntax:**
```vim
:BeadsFilter priority:P1,P2,P3
:BeadsFilter status:open,in_progress,closed
:BeadsFilter assignee:alice,bob
:BeadsFilter priority:P1,status:open,assignee:alice
```

**Supported Filters:**
- `priority` - Filter by task priority (P1, P2, P3)
- `status` - Filter by status (open, in_progress, closed)
- `assignee` - Filter by assignee name (fuzzy matching)

**Features:**
- Multiple filter values combined with OR within the same type
- Different filter types combined with AND logic
- Display shows filtered count (e.g., "5/12 tasks")
- Clear visual indication of active filters

### Fuzzy Finder Integration

The plugin provides integrated fuzzy finder support with multiple backends:

**Supported Backends:**
- **telescope.nvim** - Full-featured, highly configurable picker
- **fzf-lua** - Fast, command-line like fuzzy finder
- **builtin** - Native Neovim vim.ui.select (always available)

**Commands:**

```vim
" Find and select a task with fuzzy finder
:BeadsFindTask

" Find and update task status interactively
:BeadsFindStatus

" Find and update task priority interactively
:BeadsFindPriority

" Switch between fuzzy finder backends
:BeadsSetFinder telescope|fzf_lua|builtin
```

**Features:**
- Automatic backend detection and fallback
- Graceful degradation to builtin picker if external finders unavailable
- Smart backend selection (telescope > fzf-lua > builtin)
- Switch backends at runtime with `:BeadsSetFinder`
- Each finder displays formatted task information

### Statusline Integration

Display beads task information directly in your statusline for quick overview:

**Available Components:**
- `count` - Simple task count `[5]`
- `short` - Abbreviated format `Beads:1/5`
- `indicator` - Status breakdown `[○2 ◐1 ✓2]`
- `priority` - Priority breakdown `[P1:2 P2:3]`

**Commands:**

```vim
" Show the statusline component format
:BeadsStatusline

" Enable statusline display
:BeadsStatuslineEnable

" Disable statusline display
:BeadsStatuslineDisable
```

**Usage Examples:**

Add to your neovim config (init.vim or init.lua):

```lua
-- Using default format
require('beads').setup()
local statusline_component = require('beads.statusline').register_statusline_component()
-- Then add to your statusline: set statusline=%{luaeval('beads_statusline()')}

-- Or build custom format
local sl = require('beads.statusline')
sl.setup({
  enabled = true,
  format = sl.build_format({ "short", "indicator", "priority" })
})
```

**Features:**
- Smart caching to minimize performance impact
- Graceful fallback when tasks unavailable
- Configurable update intervals
- Custom format function support
- Automatic symbol display (○ ◐ ✓)

### Keymaps

With default configuration enabled:

- `<leader>bd` - Show task list
- `<leader>bc` - Create new task
- `<leader>bs` - Sync tasks
- `<leader>br` - Refresh task list
- `<leader>bf` - Open filter prompt
- `<leader>bF` - Clear all filters
- `<leader>bt` - Find task with fuzzy finder
- `<leader>bS` - Find and update task status
- `<leader>bP` - Find and update task priority
- `<leader>bsl` - Show statusline component

In task list:
- `q` - Close window
- `<CR>` - View task details
- `r` - Refresh list
- `f` - Open filter input dialog
- `c` - Clear all filters

## Plugin Architecture

### Modules

- **`lua/beads/init.lua`** - Main plugin module, configuration and setup
- **`lua/beads/cli.lua`** - Beads CLI command wrapper
- **`lua/beads/ui.lua`** - UI components (floating windows, buffers)
- **`lua/beads/filters.lua`** - Task filtering logic
- **`lua/beads/commands.lua`** - Neovim user commands
- **`lua/beads/keymaps.lua`** - Default keymaps
- **`lua/beads/fuzzy.lua`** - Fuzzy finder abstraction layer
- **`lua/beads/fuzzy_telescope.lua`** - Telescope.nvim picker implementation
- **`lua/beads/fuzzy_fzf.lua`** - fzf-lua implementation
- **`lua/beads/fuzzy_builtin.lua`** - Built-in vim.ui.select implementation
- **`lua/beads/statusline.lua`** - Statusline/tabline integration
- **`lua/beads/sync.lua`** - Real-time synchronization with Beads

### Plugin Entry Point

- **`plugin/beads.lua`** - Loaded automatically by Neovim on startup

## Development

To develop the Neovim plugin itself:

1. Explore the Beads integration patterns in this repository
2. Build Lua modules for Neovim in `lua/` directory
3. Test with Neovim's plugin development workflow
4. Track features and bugs using `bd` commands

### Running Tests

Tests are located in `tests/` and use a testing framework compatible with Lua.

```bash
# Run all tests
nvim --noplugin -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
```

## Resources

- [Beads Documentation](https://github.com/steveyegge/beads)
- [Neovim Plugin Development Guide](https://neovim.io/doc/user/plugin/)
- [Plugin Documentation](doc/beads.txt) - Full help documentation
- [AGENTS.md](AGENTS.md) - Detailed workflow for AI agents

## License

TBD
