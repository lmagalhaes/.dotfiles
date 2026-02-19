---
description: Safely clean up a worktree after work is complete
model: haiku
allowed-tools:
  - Bash
  - Read
---

# 💡 MODEL OPTIMIZATION

This command uses **Haiku model** for cost efficiency:
- Task is simple git operations and validation
- No complex reasoning required - just safety checks and cleanup
- 80% cost reduction vs Sonnet (~$0.25/M vs $3/M input tokens)

**Expected token usage:** ~500-800 tokens

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

- `/finish-ticket` - Clean up current worktree

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
   - Extract ticket ID from branch name (part before first hyphen)
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

### 4. Update Docs Index:
   - Find project root: `~/.claude/scripts/project-docs.sh root`
   - Check if `{project_root}/.claude/docs/index.md` exists
   - If it exists:
     - Read the file
     - Find the entry for `[branch-name]` under `## Active Worktrees`
     - If found: move the line to `## Completed Worktrees` (create section if missing) and append ` ✓`
     - Update the `_Last updated_` date
     - Write the file back
   - If index doesn't exist or entry not found: skip silently (not fatal)
   - Display: "✓ Docs index updated"

### 5. Exit Worktree:
   - Change directory: `cd [parent-repo-path]`
   - Verify successful cd: `pwd -P`
   - Display: "✓ Exited worktree"

### 6. Delete Worktree:
   - Use git wt-* alias: `git wt-rm [branch-name]`
   - Wait for deletion to complete
   - Verify deletion: `git worktree list` (worktree should be gone)
   - Display: "✓ Worktree deleted"

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
