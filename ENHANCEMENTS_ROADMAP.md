# nvim-beads Enhancement Roadmap

This document outlines the planned enhancements for nvim-beads based on feedback from the initial implementation. All items are tracked as Beads issues and ready for development.

## Overview

The core nvim-beads plugin is complete with all essential features. These enhancements add power-user capabilities, integrations, and quality-of-life improvements while maintaining the CLI-first design philosophy.

## Enhancement Categories

### 1. User Experience Enhancements

#### nvim-beads-3a5: Advanced Filtering
**Priority:** P2
**Status:** Open
**Description:**
Implement task filtering in the UI to allow users to filter the task list by priority (P1, P2, P3), status (open, in_progress, closed), and assignee. Should support combining multiple filters.

**Benefits:**
- Quickly find relevant tasks in large task lists
- Focus on high-priority or blocked items
- Filter by team members

**Implementation Notes:**
- Add filter state to UI module
- Update task list display to respect filters
- Add command-line options: `:Beads priority:P1`, `:Beads status:in_progress`
- Support filter chaining

---

#### nvim-beads-f14: Integrate Fuzzy Finder for Task Search
**Priority:** P2
**Status:** Open
**Description:**
Add integration with fzf.lua or telescope.nvim to provide fuzzy search capability for finding and selecting tasks quickly. Should support searching by ID, title, description, and status.

**Benefits:**
- Much faster task navigation
- Familiar interface for users with other plugins
- Support for preview panes

**Implementation Notes:**
- Optional dependency (telescope.nvim or fzf.lua)
- Create new module: `lua/beads/integrations/fuzzy.lua`
- Support both telescope and fzf with fallback
- Add command: `:BeadsTelescope` or `:BeadsFuzzy`

---

#### nvim-beads-7z9: Add Statusline/Tabline Integration
**Priority:** P2
**Status:** Open
**Description:**
Display Beads information in the statusline or tabline, such as: task count, sync status, currently selected task ID, last sync time. Support both lualine and custom statusline formats.

**Benefits:**
- Always-visible task count
- Know sync status at a glance
- Context about current work

**Implementation Notes:**
- Create module: `lua/beads/integrations/statusline.lua`
- Support lualine format and custom statusline
- Expose functions for: `%{get_task_count()}`, `get_sync_status()`, `get_last_sync_time()`
- Use theme colors for different sync states

---

#### nvim-beads-3nj: Implement Theme Support with Customizable Highlight Colors
**Priority:** P2
**Status:** Open
**Description:**
Add highlight groups for different task priorities and statuses. Allow users to customize colors in their configuration. Support dark and light theme variants.

**Benefits:**
- Visual distinction between task types
- Integration with Neovim color schemes
- Accessibility improvements with theme awareness

**Implementation Notes:**
- Define highlight groups: `BeadsP1`, `BeadsP2`, `BeadsP3`, `BeadsOpen`, `BeadsInProgress`, `BeadsClosed`
- Auto-detect dark/light theme and adjust
- Allow override in setup() config
- Use vim.highlight.create()

---

### 2. Performance & Reliability

#### nvim-beads-2xu: Improve Async Operations and User Feedback
**Priority:** P2
**Status:** Open
**Description:**
Use vim.notify for better async feedback, add progress indicators for long-running operations (sync, list loading). Implement cancellation support and timeout handling.

**Benefits:**
- Better user feedback during operations
- Ability to cancel long operations
- More responsive UI

**Implementation Notes:**
- Replace simple notifications with progress notifications
- Add cancellation token support to CLI operations
- Implement timeouts for all CLI calls
- Use vim.notify with proper levels (INFO, WARN, ERROR)

---

#### nvim-beads-nd4: Add Task List Caching and Performance Optimization
**Priority:** P2
**Status:** Open
**Description:**
Implement client-side caching of task list between syncs to reduce CLI overhead. Add debouncing for rapid commands. Support incremental updates instead of full refreshes.

**Benefits:**
- Faster task list display
- Reduced CLI calls
- Smoother interaction

**Implementation Notes:**
- Cache task list in UI module state
- Implement LRU cache with TTL
- Add debouncing utility for rapid commands
- Track cache invalidation via sync events
- Benchmark before/after performance

---

### 3. Integrations

#### nvim-beads-4o1: Implement Integrations with External Issue Trackers
**Priority:** P2
**Status:** Open
**Description:**
Add support for syncing with GitHub Issues, GitLab Issues, and JIRA. Allow mapping Beads tasks to external issues. Support bidirectional sync with pull/push operations.

**Benefits:**
- Work in Neovim while maintaining other project trackers
- Single source of truth flexibility
- Team collaboration across platforms

**Implementation Notes:**
- Create module: `lua/beads/integrations/external.lua`
- Implement adapters for GitHub, GitLab, JIRA
- Use their respective APIs
- Track mappings: `task_id -> external_id`
- Add commands: `:BeadsPushToGithub`, `:BeadsPullFromGithub`, etc.
- Handle conflict resolution

---

### 4. Workflow Enhancement

#### nvim-beads-2uc: Create Task Template System for Common Workflows
**Priority:** P2
**Status:** Open
**Description:**
Allow users to define task templates with default fields, descriptions, and checklists. Support quick task creation from templates. Include built-in templates for bug reports, features, and documentation.

**Benefits:**
- Consistent task structure
- Faster task creation
- Better task organization

**Implementation Notes:**
- Create module: `lua/beads/templates.lua`
- Template format: YAML or JSON in `.beads/templates/`
- Built-in templates: bug, feature, documentation, chore
- Command: `:BeadsCreateFromTemplate <template_name>`
- Support variable substitution: `{{date}}`, `{{author}}`, etc.

---

## Implementation Priority Matrix

### High Impact, Low Effort
1. **nvim-beads-7z9** - Statusline integration (quick wins with visibility)
2. **nvim-beads-3nj** - Theme support (improves UX significantly)
3. **nvim-beads-nd4** - Caching (big performance improvement)

### High Impact, Medium Effort
1. **nvim-beads-3a5** - Advanced filtering (very useful)
2. **nvim-beads-2xu** - Better async operations (improves reliability)
3. **nvim-beads-2uc** - Task templates (workflow improvement)

### Medium Impact, Medium Effort
1. **nvim-beads-f14** - Fuzzy finder (nice to have, optional dependency)

### High Impact, High Effort
1. **nvim-beads-4o1** - External integrations (complex but powerful)

## Development Guidelines

### Before Starting
- Review the existing implementation in `IMPLEMENTATION_SUMMARY.md`
- Understand the architecture in `README.md#Plugin-Architecture`
- Read the complete help: `:help beads`

### During Development
- Follow the existing code style and module structure
- Keep modules focused and single-purpose
- Add tests for new functionality
- Update documentation and help files
- Use `bd update <id> --status in_progress` when starting

### After Completion
- Run tests and verify all commands work
- Update README if adding user-facing features
- Update help file (doc/beads.txt)
- Use `bd close <id>` when complete
- Push changes: `bd sync && git push`

## Module Organization

New integrations should follow this pattern:

```
lua/beads/
├── integrations/
│   ├── statusline.lua      # Statusline/tabline support
│   ├── fuzzy.lua          # Telescope/fzf integration
│   └── external.lua       # GitHub/GitLab/JIRA sync
├── templates.lua          # Task template system
└── cache.lua              # Caching utilities
```

## Compatibility Notes

- Maintain Neovim >= 0.5 compatibility
- Gracefully handle missing optional dependencies (telescope, fzf)
- Fallback to simpler implementations when advanced features unavailable
- Test with and without optional dependencies

## Success Criteria

Each enhancement should:
- Not break existing functionality
- Include documentation updates
- Have test coverage
- Be backwards compatible
- Follow Neovim plugin conventions
- Improve user experience measurably

## Next Steps

1. Start with **nvim-beads-7z9** (statusline) - quick win
2. Continue with **nvim-beads-3nj** (themes) - foundational
3. Add **nvim-beads-nd4** (caching) - performance
4. Implement remaining features based on priority

---

**Last Updated:** 2026-01-12
**Status:** Ready for Development
**Issues Tracked:** 8 enhancement beads
