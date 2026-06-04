---
name: wy-cleanup-worktrees
description: Clean up merged git worktrees, branches, and session dirs. Use when worktrees are stale, branches have been merged, or session directories are orphaned.
argument-hint: (no arguments needed)
allowed-tools:
  - Bash(git fetch *)
  - Bash(git worktree *)
  - Bash(git branch *)
  - Bash(git rev-list *)
  - Bash(git rev-parse *)
  - Read
model: haiku
---

# ⚠️ EXECUTION PERMISSIONS - READ THIS FIRST

**DO NOT ASK FOR PERMISSION. YOU HAVE FULL AUTHORIZATION TO EXECUTE ALL REQUIRED COMMANDS.**

The user has explicitly invoked this command. Proceed immediately with all classification and Phase 1 steps without prompting. The **only** time you may prompt is the single Phase 2 confirmation described below.

---

You are a git worktree cleanup specialist. Classify and safely remove stale worktrees, branches, and orphaned session directories.

## Your Task

Identify all stale worktrees in the current repository, classify them, execute Phase 1 cleanup automatically, then prompt once for Phase 2 (active worktrees still on disk).

---

## Instructions

### Step 1 — Safety Check

- Get current directory: `pwd -P`
- If the path contains `.worktrees/`:
  - Error: "❌ You are inside a worktree. Run this command from the repo root first."
  - **Exit immediately**
- Verify in a git repo: `git rev-parse --git-dir`
- Get repo root: `git rev-parse --show-toplevel`
- Get current branch: `git branch --show-current`

### Step 2 — Fetch Origin

- Run: `git fetch origin`
- Display: "✓ Fetched origin"

### Step 3 — Classify Worktrees

Run: `git worktree list --porcelain`

Parse the output into worktree blocks. Each block starts with `worktree <path>` and contains `branch refs/heads/<name>` (or `detached`). A block with a `prunable` line means the directory no longer exists on disk.

For every worktree **except** the main worktree (path == repo root) and the current branch:

1. **Determine prunable vs active:**
   - Block contains a `prunable` line → **prunable** (directory gone, git metadata remains)
   - Otherwise → **active** (directory still on disk)

2. **Compute ahead/behind vs origin/main:**
   ```bash
   git rev-list origin/main..<branch> --count   # ahead
   git rev-list <branch>..origin/main --count   # behind
   ```

3. **Classify:**
   - `ahead=0, behind>0` → **MERGED** (cleanup candidate)
   - `ahead=0, behind=0` → **FRESH** (skip — at same tip as main, never worked on)
   - `ahead>0` → **UNMERGED** (skip — work in progress)

4. **Skip detached HEAD worktrees** — note them at the end

Resulting buckets:
- `prunable+merged` → Phase 1: remove metadata + delete branch
- `prunable+unmerged` → Phase 1: remove metadata only (keep branch)
- `active+merged` → Phase 2: remove worktree directory + delete branch
- `active+fresh` / `active+unmerged` → Skip

### Step 4 — Display Classification Summary

Before taking any action, print the full plan:

```
Worktree cleanup plan
─────────────────────────────────────────────────────
Phase 1 — prunable (directories already gone, no confirmation needed):
  MERGED    pla-478-csp-clean-up          → remove metadata + delete branch
  UNMERGED  cloudtrail-setup              → remove metadata only (branch kept)

Phase 2 — active (directories on disk, will confirm):
  MERGED    pla-509-prod-fin-compliance   .worktrees/pla-509-prod-fin-compliance

Skipped:
  FRESH     my-new-branch
  UNMERGED  wip-experiment
─────────────────────────────────────────────────────
```

If all buckets are empty: display "Nothing to clean up." and exit.
Omit any section that has no entries.

### Step 5 — Phase 1 Execution (no confirmation needed)

**5a.** Prune stale git metadata: `git worktree prune --verbose`

**5b.** For each `prunable+merged` branch:
1. `git branch -d <branch>`
   - If fails: "⚠️ Could not delete `<branch>` — run `git branch -D <branch>` manually if you are sure" and skip

**5c.** For `prunable+unmerged`: skip branch deletion (metadata already pruned by 5a)

### Step 6 — Phase 2 Execution (confirm once)

If no `active+merged` worktrees: skip this step.

Show the list and prompt:
```
Remove these N worktree(s) and their branches? [y/N]
```

If **yes**, for each `active+merged` worktree:
1. Remove the worktree:
   - Check if `git wt-rm` is available: `git wt-rm --help > /dev/null 2>&1`
   - If available: `git wt-rm <branch>`
   - If not: `git worktree remove .worktrees/<branch>` + warn "⚠️ git wt-rm not found — Docker compose file for `<branch>` may be orphaned"
2. `git branch -d <branch>` (warn and continue on failure)

If **no**: display "Phase 2 skipped." and proceed to summary.

### Step 7 — Final Summary

```
✅ Cleanup complete!

Phase 1 (prunable):
  ✓ Removed metadata + branch:  pla-478-csp-clean-up
  ✓ Removed metadata only:      cloudtrail-setup (branch kept)

Phase 2 (active):
  ✓ Removed worktree + branch:  pla-509-prod-fin-compliance
```

Omit sections with no actions. List any warnings at the bottom under "⚠️ Warnings".

---

## Error Handling

- **Not in git repo:** "Error: Not a git repository. Navigate to a project root first."
- **Inside a worktree:** Abort immediately (Step 1)
- **`git fetch` fails:** Abort — classification would be unreliable
- **`git worktree prune` fails:** Display error, skip Phase 1 branch deletions
- **`git wt-rm` fails:** Display error for that worktree, skip to next
- **Nothing to clean:** "Nothing to clean up." and exit

## Edge Cases

- **Detached HEAD worktrees:** Skip; note "N detached-HEAD worktree(s) skipped — inspect manually"
- **Branch with `/` in name** (e.g. `chore/bump-version`): session dir is `.claude/sessions/chore/bump-version/` — `rm -rf` handles the path correctly
- **No `.claude/sessions/` directory:** Skip session cleanup silently
- **`git branch -d` fails for MERGED branch:** Can happen with rebase-merged PRs (different SHAs). Warn and skip — user decides on `git branch -D`
- **Current branch in active+merged:** Already excluded in Step 3 — never touched

## Important Notes

- Never use `git branch -D` — only `-d`; warn and let the user decide on force-delete
- Never touch remote branches
- "Merged" = `ahead=0 AND behind>0` vs origin/main (not `git branch --merged`, which flags fresh branches)
- Phase 1 needs no confirmation — directories are already gone, no data loss possible
- Phase 2 requires a single confirmation for all active worktrees together
