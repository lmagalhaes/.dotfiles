# Global Developer Preferences - Leandro Magalhães

This file contains **universal** developer preferences that apply across all projects and languages.
Language-specific and domain-specific preferences are in separate context files.

---

## About Me

**Name:** Leandro Magalhães
**Role:** Sr Software Engineer / Jr-Mid Level DevOps
**Location:** Australia/Sydney (AEDT/AEST)
**Work Context:** Mix of personal projects and company challenges

---

## Context Loading System

### How It Works
This CLAUDE.md contains only universal principles. Language and domain-specific contexts are loaded on-demand from `~/.claude/contexts/`:

- **python.md** - Python tooling, standards (Ruff, mypy, pytest, uv)
- **php.md** - PHP standards (PSR-12, Composer)
- **devops.md** - AWS, Terraform, infrastructure, security
- **bash.md** - Shell scripting standards and patterns

### Loading Contexts

**Automatic Detection:**
- Project has `.py` files or `pyproject.toml` → Load `contexts/python.md`
- Project has `.php` files or `composer.json` → Load `contexts/php.md`
- Project has `.tf` files → Load `contexts/devops.md`
- Working with shell scripts → Load `contexts/bash.md`

**Manual Loading:**
When I explicitly mention working with a specific language or domain, read the appropriate context file from `~/.claude/contexts/`.

**Project-Level:**
Each project may have `.claude/CLAUDE.md` that specifies which contexts to load. Always check project-level files for specific context requirements.

---

## Universal Coding Principles

These principles apply to **all languages and projects**.

### General Principles
- **Let formatters handle style** - Don't override defaults without reason
- **Consistency is paramount** - Follow established patterns
- **Self-documenting code** - Clear names over comments
- **Explain "why", not "what"** - Comments for reasoning, not mechanics
- **Project standards first** - Local conventions override global preferences

### Code Quality Philosophy

#### Readability First
- **Prefer readability over clever code** - Be nice to your future self
- **Avoid one-liners unless trivial** - Complex logic deserves clarity
- **No unnecessary abbreviations** - Use full, meaningful names

#### Simplicity & Structure
- **KISS (Keep It Simple, Stupid)** - Don't overcomplicate things
- **Logical structure** - Code should flow naturally
- **Extract complexity** - Create variables for multi-conditional ifs, functions for complex logic
- **Meaningful names** - Variables and functions must be self-explanatory

#### Best Practices
- **Follow SOLID principles** - Single responsibility, open/closed, etc.
- **Know design patterns** - Use when appropriate, don't force them
- **Object Calisthenics awareness** - Use judiciously (details below)

#### Change Management
- **Only change relevant code** - Don't modify unrelated code unnecessarily
- **Avoid introducing bugs** - Unnecessary changes = unnecessary risk
- **Refactor with purpose** - Have a clear reason for each change

---

## Object Calisthenics Guidelines

These are constraints that improve OO design. Apply pragmatically across all OO languages:

**Core Rules (Always Apply):**
1. ✅ **One level of indentation per method** - Extract methods, keep simple
2. ✅ **No else keyword** - Use guard clauses and early returns
3. ✅ **Don't abbreviate** - Full, meaningful names
4. ✅ **Keep entities small** - Small classes, short methods

**Flexible Rules (When It Improves Readability):**
5. ⚠️ **Wrap primitives** - For domain concepts (Email, Money, etc.)
6. ⚠️ **First class collections** - When it clarifies intent
7. ⚠️ **One dot per line** - Avoid train wrecks, but fluent APIs are fine
8. ⚠️ **Limit instance variables** - Keep low; too many = doing too much
9. ⚠️ **Tell, don't ask** - Prefer commands over getters, but honor language idioms

**Example - No Else (Preferred):**
```
# Guard clause pattern (applies to all languages)
function process_user(user):
    if not user.is_active:
        return
    if not user.has_permission():
        return
    user.grant_access()
```

**Example - Extract Complexity:**
```
# Named variables for clarity
function should_grant_access(user):
    is_eligible = user.is_active and user.has_permission()
    has_valid_subscription = user.subscription.is_active()
    return is_eligible and has_valid_subscription
```

---

## Documentation Standards

### Comments
- Explain reasoning and edge cases, not obvious structure
- ❌ No unnecessary comments like `# Arrange`, `# Act`, `# Assert`
- ❌ No comments that just restate what code does
- ✅ Comments that explain WHY, not WHAT

### Error Handling
- Consider edge cases
- Fail fast with clear error messages
- Use defensive programming for public APIs
- Never hide or swallow errors

---

## Testing Philosophy

### Approach: Test-Driven Development (TDD)
1. Write test first
2. Write minimal code to pass
3. Refactor with confidence

### Coverage
- **All new code should have tests**
- **Exceptions:** Trivial getters/setters, obvious code
- **Focus:** Test behavior, not implementation

### Test Quality
- Descriptive test names (describe what and why)
- One assertion per test (when reasonable)
- Arrange-Act-Assert pattern (but don't comment it)
- Fast, independent, repeatable tests

---

## Git & Version Control

### Development Tools
- **Git** - Primary VCS
- **Editors:** PyCharm (heavy dev), vim (quick edits)
- **Dotfiles:** Managed in `~/.dotfiles/`

### Commit Messages

**Style:** Descriptive (not Conventional Commits)

**Structure:**
```
Brief summary of what and why changed

Optional body with more context if needed.
Keep body succinct and self-explanatory.
Avoid highly complex explanations.
```

**Principles:**
- Explain **WHAT** changed and **WHY**
- The **HOW** is in the code itself
- Body message only when needed for clarity
- Keep it concise - avoid unnecessary verbosity
- **No AI co-author signatures**

**Good Examples:**
```
Add user configuration management

Stores user preferences in ~/.config/app/
Supports AWS defaults and CLI display settings
```

```
Fix module-level code in email plugin

Moves email sending from import-time to command execution
Resolves startup message appearing on every CLI invocation
```

**Bad Examples:**
```
Updated files                    # Too vague
feat: add config plugin         # We don't use conventional commits
Fixed stuff                     # Not descriptive
```

### Commit Size
- Atomic commits when logical
- Group related changes together
- Don't artificially split if it breaks coherence

### Git Worktree Workflow

**Overview:**
Use git worktrees for parallel development on multiple tickets/branches simultaneously.
Each worktree gets its own isolated Docker containers accessible via unique URLs.

**Documentation:**
For detailed architecture and troubleshooting, read: `~/.dotfiles/.claude/docs/parallel-worktree-docker.md`

**Preferences:**
- **Always use wt-* aliases** instead of `git worktree` commands:
  - `git wt-create` instead of `git worktree add` (also sets up Docker)
  - `git wt-list` or `git wt-ls` instead of `git worktree list`
  - `git wt-rm` instead of `git worktree remove` (also cleans up Docker)
  - `git wt-cleanup` for removing stale worktrees
  - `git wt-docker` for Docker commands in current worktree (auto-detects context)

**Branch Naming Convention:**
- Format: `[TICKET_ID]-[concise-title]`
- Example: `PLA-123-add-user-auth`, `PROJ-456-fix-login-bug`
- Worktree path: `.worktrees/[TICKET_ID]-[concise-title]`

**Ticket Workflow Commands:**
- **`/start-ticket <ticket-id>`** - Create/switch to worktree for ticket
  - Fetches ticket details from Linear
  - Creates worktree if doesn't exist (`.worktrees/[TICKET_ID]-[title]`)
  - Starts isolated Docker containers for the worktree
  - CDs into worktree
  - Rebases with main (unless instructed otherwise)

- **`/finish-ticket`** - Safe cleanup workflow
  - Checks for uncommitted changes
  - CDs out of worktree to parent repo
  - Offers to create PR or delete worktree

**Safety Rules:**
- **Never delete a worktree while pwd is inside it** - Always cd out first
- **Always rebase with main** before starting/resuming work (unless told otherwise)
- **Parallel Docker containers** - Each worktree has isolated containers; no need to stop main

**Docker URLs:**
- Main branch: `https://api.workyard.test`
- Worktrees: `https://api-{slug}.workyard.test` (e.g., `api-pla-123.workyard.test`)

**Automatic Behavior:**
When user says "let's work on ticket X" or "start ticket X":
1. Suggest using `/start-ticket X` command
2. If worktree exists, cd to it and verify it's rebased
3. If doesn't exist, create with proper naming convention

### Dynamic Working Directory (Status Line)

The status line shows Claude's current working directory, which can be changed dynamically during a session.

**Why this matters:**
- `cd` commands in Bash don't persist (each command runs in isolated shell)
- The status line reflects where Claude is "logically" working
- Useful when switching between worktrees or projects within a session

**How to change working directory:**
When user asks to "work in", "switch to", or "change to" a directory, run:
```bash
/Users/lmagalhaes/.claude/set-cwd.sh "<original_workspace>" "<new_directory>"
```

**Parameters:**
- `<original_workspace>`: Your session's original working directory (from env info at session start)
- `<new_directory>`: The directory to switch to (use absolute path)

**Example:**
```bash
# If your session started in /Users/lmagalhaes/workspace/workyard/crew-api
# and user says "work in the pla-123 worktree":
/Users/lmagalhaes/.claude/set-cwd.sh "/Users/lmagalhaes/workspace/workyard/crew-api" "/Users/lmagalhaes/workspace/workyard/crew-api/.worktrees/pla-123-feature"
```

**How it works:**
- Each Claude instance is identified by its original workspace directory
- Session mapping stored in `/tmp/claude-sessions.json`
- CWD overrides stored in `/tmp/claude-cwd-{session_id}`
- Automatically cleaned up when session ends (via SessionEnd hook)

**Important:**
- Do NOT use `cd` to change directories - it doesn't work
- Always use absolute paths
- The original workspace is in your environment info at session start

---

## Communication Preferences

### Explanation Style
- **Balance detail with brevity** - Find the sweet spot
- **Be thorough but concise** - Don't over-explain trivial things
- **Show code examples** - When helpful, skip for trivial changes
- **Explain trade-offs** - Present alternatives unless trivial (ask if unsure)

### Interaction Style
- **Ask clarifying questions** - Don't assume when ambiguous
- **Tone:** Flexible - mix of formal and casual is fine
- **Proactive suggestions:** Welcome for task-related improvements (with test coverage)
- **Point out gotchas:** Highlight potential issues and edge cases

### Things to Avoid
- ❌ Excessive apologies
- ❌ Filler phrases like "Let me help you with that"
- ❌ Verbose explanations for simple concepts
- ❌ Anything that adds reading time without value

**Core Philosophy:** More reading = more tiring. Be efficient with words.

---

## Preferences for AI Agents

### File Access Boundaries

When working in a project directory:
- **Default scope:** Current working directory and subdirectories only
- **Cross-project access:** Only when explicitly requested (e.g., "compare with crew-runtime")
- **Search operations:** Stay within current project unless I specify otherwise
- **Current project boundary:** Working directory (`pwd`)

**Examples:**
- ✅ "Search for database models" → Search only current project
- ✅ "Find all Python files" → Only in current working directory
- ⚠️ "How does auth work across our apps?" → Ask for confirmation before searching multiple projects
- ✅ "Compare this with crew-runtime's approach" → Explicitly allows cross-project access

### Performance Tools Preferences

When using the Bash tool, **always prefer** these installed performance tools over standard Unix utilities:

**File/Content Search:**
- ✅ Use `rg` (ripgrep) instead of `grep` - Faster, smarter defaults, respects .gitignore
- ✅ Use `fd` instead of `find` - Faster, simpler syntax, respects .gitignore
- ✅ Use `fzf` for interactive selection when appropriate

**File Display:**
- ✅ Use `bat` instead of `cat` - Syntax highlighting, git integration, auto-paging
- ✅ Use `eza` instead of `ls` - Color coding, git status, icons, tree view
- ✅ Use `tree` for deep directory visualization (eza has built-in tree too)

**Navigation:**
- ✅ Use `zoxide` (z) for smart directory jumping - Learns most-used paths
  ```bash
  z crew     # Jumps to ~/workspace/workyard/crew-api
  z api wt   # Jumps to crew-api/.worktrees/...
  ```

**Monitoring & Display:**
- ✅ Use `htop` instead of `top` - Better visualization and interaction
- ✅ Use `duf` instead of `df` - Colorful disk usage, clearer output
- ✅ Use `pv` for progress monitoring in pipes (e.g., `pv file.tar.gz | tar xz`)

**Git:**
- ✅ Use `delta` as git pager - Syntax-highlighted diffs, side-by-side view
  ```bash
  git config --global core.pager delta
  ```

**Data Processing:**
- ✅ Use `jq` for JSON parsing/manipulation (not `grep`, `sed`, or `awk`)
- ✅ Use `yq` for YAML parsing/manipulation

**File Operations:**
- ✅ Use `pigz` instead of `gzip` for parallel compression (faster on multi-core)
- ✅ Use `rsync` instead of `cp` for large file operations (progress, resume support)
- ✅ Use `watchexec` for file watching instead of manual polling loops

**Examples:**
```bash
# ✅ Good - Using performance tools
rg "TODO" --type py                    # Instead of: grep -r "TODO" *.py
fd "test.*\.py$"                       # Instead of: find . -name "test*.py"
bat script.py                          # Instead of: cat script.py
eza -la --git                          # Instead of: ls -la
z proj                                 # Instead of: cd ~/long/path/to/project
duf                                    # Instead of: df -h
tar czf - large_dir | pv | cat > backup.tar.gz  # Show progress
jq '.users[] | select(.active)' data.json       # Parse JSON

# ❌ Avoid - Slower alternatives
grep -r "pattern" .
find . -name "*.log" -type f
cat file.py
ls -la
cd /full/path/to/directory
df -h
gzip large_file.tar                    # Use pigz for multi-core compression
```

**Important Notes:**
- These tools are installed via Homebrew (see `~/.dotfiles/Brewfile`)
- Prefer dedicated Claude tools (Read, Grep, Glob) over Bash when available
- Only use Bash tool when shell execution is truly required
- Performance tools are especially valuable for large codebases/files
- **Setup required for some tools:**
  ```bash
  # Enable zoxide (add to ~/.bashrc)
  eval "$(zoxide init bash)"

  # Enable delta for git
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  ```

### When Helping with Code
1. **Follow existing patterns** - Read and match established conventions
2. **Test coverage required** - No production code without tests (TDD)
3. **Explain trade-offs** - Help make informed decisions
4. **Ask when uncertain** - Don't assume requirements
5. **Load appropriate contexts** - Read language/domain-specific context files as needed

### Efficiency Guidelines (Token Optimization)

**Gather context efficiently:**
- Read necessary files upfront in parallel (not one-by-one)
- Use Grep/Glob directly for simple, targeted queries
- Use Task agents only for exploration (10+ search attempts expected)

**Respond efficiently:**
- Be complete but concise - explain once, thoroughly
- Keep responses focused on current task
- Exit sessions promptly when tasks complete (use `/wrap-session`)

**Avoid inefficiency:**
- Don't make serial tool calls that could be parallel
- Don't over-use Task agents for simple queries
- Don't give terse answers that need follow-up clarification

### When Suggesting Improvements
- ✅ Suggest if related to current task
- ✅ Suggest if significantly improves code quality
- ✅ Suggest if fixes potential bugs
- ⚠️ Ask first if major refactoring required
- ❌ Don't suggest style changes (let formatters handle it)

### Documentation Updates
- Update when functionality changes
- Keep project docs current
- Document learnings after significant work
- Maintain `.claude/` directory structure in projects

### Documentation Management (Worktree-Aware)

**Always save docs to the project root**, not the current working directory:

```bash
# Find project root from anywhere (main branch or any worktree)
PROJECT_ROOT="$(~/.claude/scripts/project-docs.sh root)"
DOCS_DIR="$(~/.claude/scripts/project-docs.sh docs-dir)"   # = $PROJECT_ROOT/.claude/docs
WORKTREE="$(~/.claude/scripts/project-docs.sh worktree)"   # branch name, empty if main
```

**Directory structure:**
```
{project_root}/.claude/docs/
├── index.md                  # Master index - always keep current
├── shared/                   # Project-wide knowledge (patterns, ADRs, gotchas)
└── {branch-name}/            # Per-worktree docs (created by /start-ticket)
    ├── index.md              # Ticket metadata + file list
    └── ...topic files...
```

**Rules:**
- Worktree docs → `{docs_dir}/{branch-name}/`
- Main branch docs → `{docs_dir}/` directly
- Non-git projects → `{cwd}/.claude/docs/`
- Always update `index.md` when creating or completing a docs folder

**Master index format** (`{docs_dir}/index.md`):
```markdown
# Project Docs Index
_Last updated: YYYY-MM-DD_

## Active Worktrees
- **[{branch}/]({branch}/)** `TICKET-ID` - Brief summary

## Completed Worktrees
- **[{branch}/]({branch}/)** `TICKET-ID` - Brief summary ✓

## Shared
- [shared/](shared/) - Project-wide knowledge
```

**Per-worktree index format** (`{docs_dir}/{branch}/index.md`):
Start with ticket metadata (ID, status, Linear URL), then a 1–2 sentence summary, then a file list with one-line descriptions.

### Context Management (Reactive)

**Respond to system warnings:**
- When you see token usage >35k in system warning, mention: "⚠️ High token usage ({tokens}k) - consider `/session-status` to check session health"
- When you see token usage >80k, suggest: "📦 Consider `/wrap-session` and starting fresh - currently at {tokens}k"

**Guide session hygiene:**
- If user completes a task (merged PR, closed ticket), suggest: "✅ Task complete! Consider wrapping: `/wrap-session` then `Ctrl+D`"
- If user switches to unrelated codebase mid-session, note: "💡 Different context - consider fresh session for clarity"

**Project memory hygiene:**
- When reading MEMORY.md >120 lines, suggest: "📝 Project memory is large ({count} lines). Consider moving old patterns to MEMORY-ARCHIVE.md"
- When creating new memories, prioritize recent patterns over old ones

**Cost awareness:**
- When suggesting Task agents for exploration, mention: "💰 Task agent keeps research out of main context"
- Remind about session costs only when relevant, not constantly

---

## Security Practices

### General Principles
- **Never commit secrets** - API keys, passwords, tokens stay out of git
- **Use secure storage** - Environment variables, secret managers, keychains
- **Validate inputs** - Sanitize and validate all user inputs
- **Principle of least privilege** - Minimal permissions necessary
- **Review dependencies** - Check for known vulnerabilities

### Secret Management
- **Environment variables** - For local development
- **Secret managers** - Cloud provider secret managers for production
- **Never log secrets** - No passwords, tokens, or PII in logs
- **Rotate credentials** - Regular rotation of API keys and passwords

### Code Security
- **Avoid SQL injection** - Use parameterized queries
- **Prevent XSS** - Sanitize output in web contexts
- **Command injection** - Never pass unsanitized input to shell commands
- **Path traversal** - Validate file paths, don't trust user input

---

## Error Messages & Logging

### Error Messages
- **User-facing errors:**
  - Clear and actionable
  - Tell them what went wrong and how to fix it
  - No technical jargon unless unavoidable
  - Example: "Configuration file not found at ~/.config/app/config.json. Run 'app init' to create it."

- **Developer errors:**
  - Include context and stack traces
  - Suggest how to fix or where to look
  - Link to docs when applicable

### Logging
- **Use appropriate levels:**
  - DEBUG: Detailed diagnostic info
  - INFO: General informational messages
  - WARNING: Something unexpected, but handled
  - ERROR: Functionality failed

- **Never log sensitive data:**
  - ❌ Passwords, tokens, API keys
  - ❌ PII (emails, names, addresses)
  - ✅ Log IDs, timestamps, error codes

- **Structured logging when possible:**
  - JSON logs for production
  - Human-readable for development

---

## Quick Reference for AI Agents

### Do:
✅ Write tests first (TDD)
✅ Load language-specific contexts as needed
✅ Ask clarifying questions when ambiguous
✅ Point out potential issues and gotchas
✅ Keep commits descriptive and concise
✅ Cover new code with tests
✅ Follow existing project patterns
✅ Check project .claude/CLAUDE.md for specific requirements
✅ Use performance tools (rg, fd, bat, eza, delta, jq, etc.) instead of standard Unix tools in Bash

### Don't:
❌ Override formatter defaults without reason
❌ Add AI co-author signatures to commits
❌ Over-explain trivial concepts
❌ Use filler phrases that don't add value
❌ Write production code without tests
❌ Assume requirements - ask when unclear
❌ Load unnecessary context files
❌ Search outside project directory without permission

---

## Session Management

### Commands

**`/session-status`** - Check token usage, session health, get recommendations
**`/wrap-session`** - Save session context to branch-keyed file
**`/wrap-session --preview`** - Show what would be saved without writing
**`/load-session`** - Show 3-line hint (default); `--full` for full content

### Automatic Session Loading (Hint-only)

**At the START of EVERY conversation in a project directory:**

1. Check if `.claude/sessions/<branch>/` exists (branch-keyed storage)
2. If a session exists for the current branch, display a **3-line hint**:
   - Session age + commit delta since save
   - `start_here` value
   - Count of open decisions + assumptions
3. Do NOT load full session content — user runs `/load-session --full` if needed
4. Proceed with user request

**Hint format:**
```
Session: <branch> (saved Nd ago · M commits) — N decisions, P assumptions open
Resume: <start_here value>
Run /load-session --full for decisions and watch-outs
```

Session auto-load is a **resume pointer only**. It is not a substitute for fresh task discovery.

### Workflow

1. **Environment:** `/start-ticket <id>` — worktree + rebase + pointer file
2. **Context hint:** Auto-load shows 3-line summary (age, start_here, open counts)
3. **Task understanding:** `/prime-context <id>` — fresh discovery from Linear/git/docs
4. **Work:** Iterate; run `/session-status` to monitor token usage
5. **Wrap:** At 150k tokens, `/wrap-session --preview` then `/wrap-session`

**Critical ordering:** Run `/load-session` (or see the auto-hint) **before** `/prime-context` so prior decisions are in context when prime-context's clarifying questions are evaluated.

**Task understanding is `/prime-context`'s job.** Do not skip it or substitute the session file for it.

### Task Agent Context Passing

When spawning Task agents, extract relevant fields from the session JSON and pass them directly in the agent prompt. Do not use a `task-context.md` intermediary. Session JSON is already compact; include only the fields the agent needs (e.g., `watch_out`, `decisions`, `next_session.start_here`).

### Auto-Wrap Triggers

**Token usage thresholds (monitored by `/session-status`):**
- 150k tokens: Strongly suggest `/wrap-session --preview` then `/wrap-session`
- **Note:** Context overflow typically occurs at ~150k, not 200k limit

### Session Storage

- **Branch-keyed:** `.claude/sessions/<branch>/session-YYYY-MM-DD-HHMMSS.json`
- **Git repos:** Stored at repo root `.claude/sessions/`
- **Worktrees:** Each branch has its own subdirectory (filesystem-enforced isolation)
- **Dotfiles:** `~/.claude/sessions/<branch>/`

### Auto-Memory vs. Session File Boundaries

These two systems serve different scopes. Do not blur them.

| | Session file | Auto-memory |
|---|---|---|
| **Scope** | Branch-local handoff | Project-wide, durable |
| **Lifetime** | Current ticket/branch | Across branches and sessions |
| **Examples** | Decisions, dead-ends, watch-outs for this ticket | Repeated user constraints, architectural patterns |

**What belongs in session files (not auto-memory):**
- In-flight task state for the current branch
- Branch-local decisions and rationale
- Session resume pointers (`start_here`)
- Assumptions and open questions from this ticket's prime-context run

**What belongs in auto-memory (not session files):**
- Cross-branch patterns that apply project-wide
- Repeated user constraints Claude should always follow
- Long-lived architectural decisions (not ticket-specific)

**Schema decision rule:** A field belongs in the session file if it requires a prior conversation to reconstruct. If `prime-context` can regenerate it from git/Linear/docs, it does not belong in the session file.

See `~/.claude/commands/README.md` for detailed documentation.

---

## Configuration Locations

**This file:** `~/.dotfiles/claude-code/CLAUDE.md`
**Symlink:** `~/.config/claude-code/CLAUDE.md` → `~/.dotfiles/claude-code/CLAUDE.md`
**Context files:** `~/.claude/contexts/*.md`
**Commands:** `~/.claude/commands/*.md`
**Project preferences:** `[project]/.claude/CLAUDE.md` (inherits from this file)

---

## Changelog

**v2.5** - 2026-05-14
- 🎯 **Session Management Refactor:** Cleaner boundaries, hint-only auto-load
- **Hint-only auto-load:** Session start now emits 3-line hint (age, start_here, open counts) instead of full replay
- **Workflow sequence clarified:** start-ticket → load-session (hint) → prime-context → work → wrap-session
- **task-context.md removed:** Pass session JSON fields directly to Task agents instead
- **Auto-memory vs session file boundaries:** New section clarifying what goes where and why
- **Branch-keyed storage documented:** Session paths updated to reflect filesystem-level branch isolation
- **Schema decision rule added:** If prime-context can regenerate it, it doesn't belong in the session file

**v2.4** - 2026-02-26
- ⚡ **Performance Tools Preferences:** Added comprehensive section for installed performance tools
- **Tool replacements:** ripgrep, fd, fzf, htop, pv, jq, yq, pigz, rsync, watchexec
- **Top 5 productivity tools added:** bat, eza, zoxide, delta, duf (immediate productivity boost)
- **Clear guidelines:** When to use each tool with practical examples
- **Better defaults:** Agents now prefer faster, modern alternatives to standard Unix tools
- **Updated Brewfile:** Added bat, eza, zoxide, git-delta, duf to package list

**v2.3** - 2026-02-12
- 🔧 **Context Management Fix:** Changed "Proactive" to "Reactive" - removed unimplementable instructions
- **Realistic expectations:** Claude cannot count messages or track token usage proactively
- **System warning triggers:** Now respond to visible token warnings (>35k, >80k)
- **Efficiency Guidelines:** Added consolidated token optimization section
- **Task completion focus:** Optimize for completing tasks efficiently, not message brevity

**v2.2** - 2026-01-19
- ⚡ **Session Management Optimization:** 85-90% token reduction achieved
- **Haiku model:** All three commands now use Haiku (80% cost reduction)
- **Compressed schema:** Session files 60-65% smaller, zero information loss
- **Tiered display:** load-session auto-selects compact/full based on size (--full, --compact, --summary flags)
- **Auto-wrap triggers:** session-status warns at 140k-150k tokens with wrap preview
- **Automatic loading:** Sessions auto-load at conversation start (MANDATORY)
- **Task agent context:** Created task-context.md system (95% token savings per spawn)
- **Efficiency scoring:** File activity tracking, token rate analysis
- **150k overflow:** Updated thresholds for actual context limits
- **Backups created:** Original files preserved in `~/.claude/commands/backups/original/`
- **Documentation:** Complete README.md overhaul with optimization results

**v2.1** - 2026-01-12
- 📦 **Session Management System:** Added session continuity commands
- Created `/wrap-session` - Save session context and learnings
- Created `/load-session` - Restore previous session context
- Updated `/session-status` - Integrated wrap-session recommendations
- Added `~/.claude/commands/README.md` - Session management documentation
- Added automatic token usage tracking and optimization suggestions
- **Git worktree support:** Sessions automatically shared across all worktrees

**v2.0** - 2025-11-27
- 🎯 **Major refactoring:** Split into modular context system
- Moved language-specific content to `~/.claude/contexts/`
- Added context loading system documentation
- Reduced core file from ~12k to ~4k tokens (66% reduction)
- Created: python.md, php.md, devops.md, bash.md contexts

**v1.1** - 2024-11-20
- Added Security Practices section
- Added Error Messages & Logging section
- Added no unnecessary comments preference
- Added Object Calisthenics guidelines with core vs flexible rules

**v1.0** - 2024-11-20
- Initial monolithic version

---

**Version:** 2.5 (Session Management Refactor — Hint-only + Boundaries)
**Last Updated:** 2026-05-14
**Token Budget:** ~4k (core only), ~7-10k (with typical contexts)

@RTK.md
