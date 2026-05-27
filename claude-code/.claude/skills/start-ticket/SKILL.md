---
name: start-ticket
description: Create/switch to worktree for a Linear ticket
argument-hint: <ticket-id> e.g. PLA-123
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Write
  - mcp__linear__get_issue
---

# ⚠️ EXECUTION PERMISSIONS - READ THIS FIRST

**DO NOT ASK FOR PERMISSION. YOU HAVE FULL AUTHORIZATION TO EXECUTE ALL REQUIRED COMMANDS.**

The user has explicitly invoked this command. By doing so, they grant you complete permission to:
- Fetch ticket details from Linear using MCP tools
- Run ALL git commands needed (status, branch, worktree, rebase)
- Read ANY files from repository (git config, worktree list, etc.)
- Create worktrees and directories
- Change working directory (cd)
- Execute git wt-* alias commands
- Create/write files in `.claude/docs/` directory

**IMPORTANT:** Do NOT prompt the user before running these operations. Proceed immediately with all necessary commands. The user expects this command to run autonomously without interruption.

**EXCEPTION:** Always ASK before switching Docker containers - user may be working on multiple projects.

---

You are a git worktree specialist. Set up a complete worktree environment.

## Your Task:

Create or switch to a worktree for the specified ticket, fetch context from Linear, and rebase with main.

## Usage:

- `/start-ticket PLA-123` - Start work on ticket PLA-123
- `/start-ticket PROJ-456` - Start work on ticket PROJ-456

## Instructions:

### 1. Parse Arguments:
   - First argument is the ticket ID (required)
   - Validate format: Should match pattern like `PLA-123`, `PROJ-456` (letters-numbers)
   - If no argument: Error "Usage: /start-ticket <ticket-id>"

### 2. Fetch Ticket Details from Linear:
   - Use `mcp__linear__get_issue` with the ticket ID
   - Extract:
     - Ticket identifier (ID)
     - Ticket title
     - Ticket description
     - Current status
     - Assignee
     - Priority
     - Estimate (for complexity assessment)
     - URL
     - Created/updated dates
   - If ticket not found: Error "Ticket [ID] not found in Linear"
   - Display brief ticket info:
     ```
     📋 Ticket: [ID] - [Title]
     Status: [Status] | Assignee: [Name] | Priority: [Priority] | Estimate: [Size]
     ```

### 3. Get Branch Name from Linear:
   - Use the `gitBranchName` field from Linear response
   - This is pre-formatted by Linear in the correct convention
   - Example: "pla-123-add-user-authentication"
   - If gitBranchName is empty, generate it:
     - Format: `[TICKET_ID]-[concise-title]`
     - Convert to lowercase, replace spaces with hyphens
     - Remove special characters (keep alphanumeric and hyphens)
     - Truncate to ~50 chars total

### 4. Check Repository Context:
   - Verify in a git repository: `git rev-parse --git-dir`
   - Get repository root: `git rev-parse --show-toplevel`
   - Check current branch: `git branch --show-current`

### 5. Check if Worktree Exists:
   - List worktrees: `git worktree list`
   - Check if worktree path `.worktrees/[branch-name]` exists
   - If exists:
     - Display: "✓ Worktree already exists: .worktrees/[branch-name]"
     - Skip to step 7 (Switch to Worktree)

### 6. Create Worktree (if doesn't exist):
   - Use git wt-* alias: `git wt-create [branch-name]`
   - This automatically:
     - Creates worktree in `.worktrees/[branch-name]`
     - Copies IDE settings
     - Handles Docker integration (may show warnings if not applicable)
   - Wait for creation to complete
   - Display: "✓ Created worktree: .worktrees/[branch-name]"

### 7. Switch to Worktree:
   - Change directory to worktree: `cd [repo-root]/.worktrees/[branch-name]`
   - Verify pwd: `pwd -P`
   - Display: "✓ Switched to worktree"

### 8. Rebase with Main:
   - Fetch latest main: `git fetch origin main`
   - Check if already up-to-date: `git merge-base --is-ancestor origin/main HEAD`
   - If not up-to-date:
     - Rebase: `git rebase origin/main`
     - If conflicts:
       - Display conflicts
       - Error: "Rebase conflicts detected. Resolve manually and run 'git rebase --continue'"
       - Do NOT continue
   - If up-to-date:
     - Display: "✓ Already up-to-date with main"
   - If rebased successfully:
     - Display: "✓ Rebased with main"

### 9. Final Summary:
   ```
   ✅ Worktree ready!

   Working directory: .worktrees/[branch-name]
   Branch: [branch-name]
   Ticket: [TICKET_ID] - [Title]

   Next steps:
   - When done, use '/finish-ticket' to clean up
   ```

## Error Handling:

- **Not in git repo:** "Error: Not in a git repository. Navigate to a project directory first."
- **Ticket not found:** "Error: Ticket [ID] not found in Linear. Check the ticket ID."
- **Linear API error:** Display error message and suggest checking Linear connection
- **Worktree creation fails:** Display git error and suggest manual inspection
- **Rebase conflicts:** Stop and instruct user to resolve manually
- **Invalid ticket ID format:** "Error: Invalid ticket ID format. Expected format: PROJ-123"

## Edge Cases:

- **Already in worktree:** If pwd is already in a worktree, warn user but continue
- **Dirty working directory:** Warn if uncommitted changes exist before rebase
- **Branch already exists:** If branch exists but not as worktree, error and suggest cleanup
- **Main branch outdated:** If local main is behind origin, fetch first
- **No Linear access:** If MCP tools unavailable, error with helpful message
## Important Notes:

- Be informative but concise with progress messages
- Use relative paths when displaying to user for brevity
- Validate ticket ID format before calling Linear API
- `.env` is automatically copied to the worktree by `git wt-create` — no manual copy needed
