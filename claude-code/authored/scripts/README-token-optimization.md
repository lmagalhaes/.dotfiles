# Token Optimization Scripts

This directory contains bash scripts designed to reduce Claude token usage by automating repetitive tasks that Claude would otherwise do manually.

## Scripts

### 1. `manage-docs-index.sh` - Master Documentation Index Management
**Token savings: ~1-2k per operation**

Handles all operations on the master `.claude/docs/index.md` file:

```bash
# Initialize new index
manage-docs-index.sh init

# Add entry to Active Worktrees
manage-docs-index.sh add-active "PLA-123-feature" "PLA-123" "Add user auth"

# Move entry to Completed
manage-docs-index.sh mark-complete "PLA-123-feature"

# List entries (JSON output)
manage-docs-index.sh list-active | jq
manage-docs-index.sh list-all | jq
```

**Used by:**
- `/start-ticket` command
- `/finish-ticket` command
- `init-worktree-docs.sh` script

---

### 2. `init-worktree-docs.sh` - Complete Worktree Documentation Setup
**Token savings: ~2-3k per ticket initialization**

Automates the entire documentation initialization process:

```bash
init-worktree-docs.sh \
  "PLA-123-feature" \
  "PLA-123" \
  "Add authentication system" \
  "In Progress" \
  "https://linear.app/company/issue/PLA-123" \
  "Implement JWT-based auth with refresh tokens"
```

**What it does:**
1. Creates `.claude/docs/{branch}/` directory
2. Generates `index.md` with ticket metadata
3. Updates master docs index (calls `manage-docs-index.sh`)
4. Creates symlink: worktree `.claude/docs` → project root docs
5. Scans codebase for existing ticket references (using `ripgrep`)
6. Provides helpful next steps

**Used by:**
- `/start-ticket` command (replaces manual Claude docs creation)

---

## Token Savings Breakdown

### Per Ticket Lifecycle
- **Start ticket:** ~2-3k tokens saved (docs initialization)
- **Finish ticket:** ~1-2k tokens saved (index update)
- **Wrap sessions:** ~500-800 tokens saved (if file list refresh added)

**Total per ticket: ~4-6k tokens saved**

### Annual Impact
Assuming 50 tickets/year:
- **200-300k tokens saved**
- **More importantly:** Fewer formatting errors, consistent structure
- **Side benefit:** Faster execution (bash vs Claude thinking + tool calls)

---

## Helper Tools Used

These scripts leverage modern CLI tools for performance:

- **ripgrep (`rg`)** - Fast code search (finds existing ticket references)
- **jq** - JSON processing (for programmatic access to lists)
- **fd** - Fast file finding (optional, for docs scanning)
- **fzf** - Fuzzy finder (future: interactive ticket selection)

All tools are native ARM on Apple Silicon - no Rosetta required.

---

## Future Scripts (Planned)

### Priority 2
3. **`refresh-worktree-index.sh`** - Auto-update file list in worktree index
   - Token savings: ~500-800 per wrap-session
   - Called by: `/wrap-session` command

### Ideas for Exploration
- **`scan-ticket-refs.sh`** - Deep scan for ticket references with context
- **`docs-search.sh`** - Search across all worktree docs (using ripgrep + fzf)
- **`archive-docs.sh`** - Archive completed ticket docs to save space

---

## Dependencies

Install via Homebrew:
```bash
brew install ripgrep jq yq fd fzf
```

All dependencies are in `~/.dotfiles/Brewfile` and will be installed with:
```bash
brew bundle --file=~/.dotfiles/Brewfile
```

---

## Testing

Each script includes comprehensive error handling and has been tested on:
- macOS (Darwin 25.2.0)
- Apple Silicon (ARM64)
- BSD utilities (awk, sed, grep)

All scripts use BSD-compatible awk patterns (no GNU-specific features).

---

**Last updated:** 2026-02-18
