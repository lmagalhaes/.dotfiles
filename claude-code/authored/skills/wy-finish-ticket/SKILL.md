---
name: wy-finish-ticket
description: Safely clean up a worktree after work is complete
argument-hint: (no arguments)
model: haiku
allowed-tools:
  - Bash
  - Read
---

# ⚠️ EXECUTION PERMISSIONS - READ THIS FIRST

**DO NOT ASK FOR PERMISSION. YOU HAVE FULL AUTHORIZATION TO EXECUTE ALL REQUIRED COMMANDS.**

The user has explicitly invoked this command. By doing so, they grant you complete permission to:
- Run ALL git commands needed (status, branch, worktree)
- Read ANY files from repository
- Change working directory (cd)
- Execute git wt-* alias commands
- Delete worktrees and branches

**IMPORTANT:** Do NOT prompt the user before running these operations. Proceed immediately with all necessary commands. The user expects this command to run autonomously without interruption.

---

You are a git worktree cleanup specialist. Safely exit and delete a worktree after work is complete.

## Your Task:

Verify work is committed, safely exit the worktree, and delete it. This command assumes the ticket is **done** (PR merged, work complete).

## Usage:

- `/wy-finish-ticket` - Clean up current worktree

## Instructions:

### 1. Verify Worktree Context:
   - Check if in a git repository: `git rev-parse --git-dir`
   - Get current directory: `pwd -P`
   - Check if in a worktree:
     - Look for `.worktrees/` in `pwd -P` path
     - OR run `git worktree list` and check if current path matches a worktree
   - If NOT in a worktree:
     - Error: "❌ Not currently in a worktree. Use this command from within a worktree directory."
     - Exit

### 2. Get Worktree Information:
   - Get current branch: `git branch --show-current`
   - Extract ticket ID from branch name — match `[a-z]+-[0-9]+` pattern (e.g. `pla-123` from `pla-123-feature-name`)
   - Get repository root: `git rev-parse --show-toplevel`
   - Calculate parent repo path: Remove `.worktrees/[branch-name]` from current path

### 3. Check for Uncommitted Changes:
   - Run: `git status --porcelain`
   - If ANY output (unstaged, staged, or untracked files):
     - Display error:
       ```
       ❌ Uncommitted changes detected

       Please commit or stash your changes before finishing the ticket.

       Current status:
       [git status output]

       Options:
       - git add . && git commit -m "Your message"
       - git stash push -u -m "WIP: [branch-name]"
       - git reset --hard (⚠️ destroys changes)
       ```
     - **Exit immediately - DO NOT continue**
   - If no output:
     - Display: "✓ Working tree clean"

### 4. Exit Worktree:
   - Change directory: `cd [parent-repo-path]`
   - Verify successful cd: `pwd -P`
   - Display: "✓ Exited worktree"

### 5. Delete Worktree:
   - Use git wt-* alias: `git wt-rm [branch-name]`
   - Wait for deletion to complete
   - Verify deletion: `git worktree list` (worktree should be gone)
   - Display: "✓ Worktree deleted"

### 6. Delete Local Branch:
   - Run: `git branch -d [branch-name]`
   - If it succeeds: display "✓ Local branch deleted"
   - If it fails (exit code non-zero):
     - Check PR state via `gh` if available:
       ```bash
       gh pr list --state merged --head [branch-name] --json number --jq 'length' 2>/dev/null
       ```
     - If result is `1` (merged PR found): run `git branch -D [branch-name]` and display "✓ Local branch deleted (squash/rebase merge detected)"
     - Otherwise: display warning and stop:
       ```
       ⚠ Could not delete branch [branch-name] — it may not be merged yet.
       If the PR is merged, run manually:
         git branch -D [branch-name]
       ```

### 7. Final Summary:
   ```
   ✅ Cleanup complete!

   Actions taken:
   - Verified working tree was clean
   - Exited worktree safely
   - Deleted worktree: .worktrees/[branch-name]
   - Deleted local branch: [branch-name]

   Current location: [pwd]

   Note: Remote branch (if exists) was NOT deleted.
   If PR is merged, delete remote branch via GitHub UI or:
     git push origin --delete [branch-name]
   ```

## Error Handling:

- **Not in worktree:** "Error: Not in a worktree. This command should be run from within a worktree directory."
- **Uncommitted changes:** Stop immediately with clear instructions (see step 3)
- **CD fails:** "Error: Failed to exit worktree. Current directory may have been deleted."
- **Worktree deletion fails:** Display git error and suggest manual cleanup: `git worktree remove [path]`
- **Worktree is main branch:** "Error: Cannot finish ticket from main branch. This command is for worktrees only."

## Edge Cases:

- **Detached HEAD:** Error "Worktree is in detached HEAD state. Checkout a branch first."
- **Stale worktree:** If worktree already deleted but git still tracking it, suggest: `git worktree prune`
- **Multiple worktrees:** Works fine - just cleans up the current one

## Important Notes:

- **NO prompts** - command runs fully automatically if working tree is clean
- **NO PR creation** - assumes PR is already merged (ticket is done)
- **NO Linear calls** - no need to fetch ticket info
- Safety first - never proceeds if uncommitted changes exist
- Always cd out before deletion (prevents pwd errors)
- Clear error messages guide user if something is wrong
- Remote branch is preserved (user can delete manually if needed)
- Use relative paths in display for brevity
- This is a "nuclear option" - worktree is permanently deleted
