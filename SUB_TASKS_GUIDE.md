# nvim-beads Sub-Tasks Guide

This document provides a comprehensive breakdown of all sub-tasks for the 8 enhancement beads. Each enhancement has been refined into 5 focused sub-tasks for easier implementation and tracking.

## Structure Overview

- **7 Enhancement Beads** - High-level features (8 - 1 closed)
- **35 Sub-Tasks** - Detailed implementation steps (5 per remaining enhancement)
- **Total 51 Beads** - Core (8 closed) + Enhancements (7 open) + Sub-tasks (35) + External (6 closed)

## Enhancement 1: Advanced Filtering

**Parent Issue:** nvim-beads-3a5
**Estimated Effort:** 8-10 hours
**Priority:** Medium

### Sub-Tasks

1. **nvim-beads-06f** - Create filter state management in UI module
   - Add filter state tracking to lua/beads/ui.lua
   - Create table to store active filters (priority, status, assignee)
   - Implement filter_state getter/setter functions
   - Support persisting filters between sessions

2. **nvim-beads-zd1** - Implement filter matching logic
   - Create filter matching functions for each filter type
   - Test each task against active filters
   - Support AND logic for combining filters
   - Add fuzzy matching for assignee names

3. **nvim-beads-w1d** - Add filter UI controls
   - Add UI elements to task list window for filter selection
   - Include buttons/keymaps to toggle filters
   - Display current active filters at top of list
   - Support interactive filter toggling with visual feedback

4. **nvim-beads-wne** - Add filter commands and keymaps
   - Create :BeadsFilter command with syntax parsing
   - Add keymaps for common filters: <leader>bf for filter menu
   - Support syntax: :BeadsFilter priority:P1,status:open
   - Persist filter state between sessions

5. **nvim-beads-8lz** - Add filter tests and documentation
   - Write tests for filter matching logic
   - Document in help file (doc/beads.txt)
   - Add examples: filtering high-priority tasks, user-assigned tasks
   - Update README with filter usage examples

---

## Enhancement 2: Fuzzy Finder Integration

**Parent Issue:** nvim-beads-f14
**Estimated Effort:** 10-12 hours
**Priority:** Medium

### Sub-Tasks

1. **nvim-beads-a5p** - Create fuzzy finder integration abstraction module
   - Create lua/beads/integrations/fuzzy.lua
   - Add abstraction layer to support both telescope.nvim and fzf.lua
   - Implement feature detection
   - Graceful fallback to regular task list when unavailable

2. **nvim-beads-lvx** - Implement telescope.nvim picker
   - Create Telescope picker for Beads tasks
   - Support previewing task details in picker
   - Handle task selection to show details
   - Support sorting by ID, title, priority, status

3. **nvim-beads-o3l** - Implement fzf.lua integration
   - Create fzf integration as fallback/alternative
   - Format task list for fzf display
   - Handle selection and action binding
   - Support preview window for task details

4. **nvim-beads-1bb** - Add fuzzy search commands
   - Create :BeadsFuzzy command as main entry point
   - Implement :BeadsTelescope and :BeadsFzf variants
   - Add keymaps: <leader>bf for fuzzy search
   - Support filtering during search

5. **nvim-beads-d9h** - Test and document fuzzy finder
   - Write tests for both telescope and fzf implementations
   - Document optional dependencies in README
   - Add usage examples for both variants
   - Test graceful fallback when dependencies missing

---

## Enhancement 3: Statusline Integration ⭐ Quick Win

**Parent Issue:** nvim-beads-7z9
**Estimated Effort:** 3-4 hours
**Priority:** High (Quick Win)

### Sub-Tasks

1. **nvim-beads-jm5** - Create statusline module in integrations
   - Create lua/beads/integrations/statusline.lua
   - Define functions to get task count, sync status, last sync time
   - Support both lualine format and custom statusline format strings
   - Initialize module on plugin setup

2. **nvim-beads-5tu** - Implement lualine integration
   - Create lualine extension for Beads
   - Display task count and sync status
   - Add theme-aware colors
   - Auto-register if lualine available, optional otherwise

3. **nvim-beads-y0b** - Implement custom statusline support
   - Add statusline functions for custom statusline string
   - Functions: beads_task_count(), beads_sync_status(), beads_last_sync()
   - Document format strings for %{...} expansion
   - Support custom formatting functions

4. **nvim-beads-5fw** - Add statusline configuration and keymaps
   - Add setup options: show_task_count, show_sync_status, sync_status_style
   - Create refresh function triggered on sync events
   - Add :BeadsStatuslineRefresh command
   - Support click handlers in lualine

5. **nvim-beads-fah** - Document statusline integration
   - Add examples to README for both lualine and custom statusline
   - Document all statusline functions in help file
   - Add configuration examples
   - Create simple usage guide

---

## Enhancement 4: Theme Support

**Parent Issue:** nvim-beads-3nj
**Estimated Effort:** 6-8 hours
**Priority:** High

### Sub-Tasks

1. **nvim-beads-bu6** - Define highlight groups and color scheme
   - Define highlight groups: BeadsP1, BeadsP2, BeadsP3, BeadsOpen, BeadsInProgress, BeadsClosed, BeadsSync, BeadsError
   - Create default colors for dark and light themes
   - Use standard Neovim color names and hex values
   - Support transparency where applicable

2. **nvim-beads-brl** - Implement theme detection and application
   - Auto-detect dark/light theme from 'background' option
   - Apply appropriate color scheme automatically
   - Handle theme changes with autocmd
   - Support manual theme override in setup()

3. **nvim-beads-753** - Add user color customization
   - Allow users to override colors in setup()
   - Support hex colors and named colors
   - Example: setup({colors = {P1 = '#ff0000', open = 'blue'}})
   - Validate color format before applying

4. **nvim-beads-t0p** - Apply highlights to UI components
   - Use highlight groups in task list display
   - Apply colors based on priority and status
   - Color code priority levels and task status
   - Update on each refresh

5. **nvim-beads-vpf** - Document theme customization
   - Add theme examples to README
   - Document all highlight groups in help file
   - Show color customization examples
   - Add theme preview/test command

---

## Enhancement 5: Async Operations Improvement

**Parent Issue:** nvim-beads-2xu
**Estimated Effort:** 8-10 hours
**Priority:** Medium

### Sub-Tasks

1. **nvim-beads-c3t** - Implement async wrapper for CLI operations
   - Create async wrapper utilities in sync.lua
   - Use vim.loop for non-blocking operations
   - Support callbacks for completion
   - Handle errors gracefully with timeout support

2. **nvim-beads-wqj** - Add progress indicators and notifications
   - Replace simple vim.notify calls with progress tracking
   - Show spinner for long operations
   - Display operation status (loading, syncing, etc)
   - Use vim.notify levels appropriately

3. **nvim-beads-k4g** - Implement operation cancellation
   - Add cancellation token support to async operations
   - Allow users to cancel long-running syncs/loads with <C-c>
   - Clean up partial state on cancellation
   - Provide feedback on successful cancellation

4. **nvim-beads-3c1** - Add timeout handling and retry logic
   - Set reasonable timeouts for all CLI operations (default 30s)
   - Show timeout warnings
   - Implement exponential backoff retry for failed operations
   - Make configurable in setup()

5. **nvim-beads-645** - Test async operations and document
   - Write async operation tests
   - Document timeout/retry configuration
   - Add examples of async patterns
   - Update help file with async behavior info

---

## Enhancement 6: Performance Optimization ⭐ High Impact

**Parent Issue:** nvim-beads-nd4
**Estimated Effort:** 10-12 hours
**Priority:** High

### Sub-Tasks

1. **nvim-beads-k4z** - Implement LRU cache for task list
   - Create cache module in lua/beads/cache.lua
   - Implement LRU (Least Recently Used) cache
   - Add TTL (time-to-live) support (configurable, default 60s)
   - Support cache invalidation on sync events

2. **nvim-beads-6tb** - Integrate cache into CLI module
   - Modify lua/beads/cli.lua to use cache
   - Cache ready() and show() responses
   - Add cache hit/miss metrics for debugging
   - Skip CLI calls when cache valid (within TTL)

3. **nvim-beads-d5d** - Implement command debouncing
   - Create debounce utility in cache module
   - Prevent rapid repeated commands (filter, search, etc)
   - Configurable debounce delay (default 300ms)
   - Test with rapid keystrokes

4. **nvim-beads-ayc** - Add incremental update support
   - Implement incremental cache updates instead of full refreshes
   - Only update changed tasks after sync
   - Preserve UI state (scroll position, filter state) on updates
   - Reduce flickering during updates

5. **nvim-beads-99s** - Benchmark and document performance improvements
   - Measure performance before/after caching
   - Document cache configuration options
   - Add benchmarks to README
   - Create performance tuning guide

---


## Enhancement 7: Task Templates

**Parent Issue:** nvim-beads-2uc
**Estimated Effort:** 8-10 hours
**Priority:** Medium

### Sub-Tasks

1. **nvim-beads-1vb** - Create template system framework
   - Create lua/beads/templates.lua
   - Define template format (YAML/JSON)
   - Implement template loading and validation
   - Store templates in .beads/templates/ directory

2. **nvim-beads-4k8** - Implement built-in templates
   - Create default templates: bug.yaml, feature.yaml, documentation.yaml, chore.yaml
   - Each template includes default fields
   - Include description template for each
   - Add checklist items for appropriate templates

3. **nvim-beads-h8n** - Add variable substitution in templates
   - Support template variables: {{date}}, {{author}}, {{branch}}
   - Implement variable resolution from environment and git
   - Allow custom variables in setup() config
   - Test variable substitution

4. **nvim-beads-vdd** - Create template commands and UI
   - Implement :BeadsCreateFromTemplate command
   - Add :BeadsListTemplates to show available templates
   - Create UI selector for template choice
   - Support fuzzy search for template selection

5. **nvim-beads-hgb** - Document template system
   - Document template format and structure
   - Show examples of each built-in template
   - Explain custom template creation process
   - Add best practices guide for workflow templates

---

## Development Workflow

### Starting a Sub-Task

```bash
# See the sub-task details
bd show nvim-beads-06f

# Mark as in progress
bd update nvim-beads-06f --status in_progress

# Work on implementation...

# Mark complete
bd close nvim-beads-06f
```

### Completing an Enhancement

All 5 sub-tasks for an enhancement must be completed before closing the parent enhancement:

```bash
# Verify all sub-tasks are closed
bd show nvim-beads-3a5

# Close the enhancement when all sub-tasks done
bd close nvim-beads-3a5
```

## Dependency Graph

Some enhancements depend on others:

```
Advanced Filtering (3a5) ──→ Statusline (7z9) ──→ Theme (3nj)
                     ↓
Performance (nd4) ──→ Caching utilities
                     ↓
Async (2xu) ─────────┘

Fuzzy Finder (f14) ──→ Optional (works with or without)

Templates (2uc) ────→ Optional (standalone feature)
```

## Success Criteria for Sub-Tasks

Each sub-task should:
- ✓ Be independently testable
- ✓ Have clear definition of done
- ✓ Include documentation updates
- ✓ Not break existing functionality
- ✓ Follow code style guidelines
- ✓ Be committed with clear commit message

## Resources

- **ENHANCEMENTS_ROADMAP.md** - High-level overview and strategy
- **IMPLEMENTATION_SUMMARY.md** - Core plugin architecture
- **doc/beads.txt** - Complete help documentation
- **README.md** - Getting started and usage guide

---

**Last Updated:** 2026-01-12
**Total Sub-Tasks:** 40
**Status:** All open and ready for development
