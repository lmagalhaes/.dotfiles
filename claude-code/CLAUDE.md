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

### When Helping with Code
1. **Follow existing patterns** - Read and match established conventions
2. **Test coverage required** - No production code without tests (TDD)
3. **Explain trade-offs** - Help make informed decisions
4. **Ask when uncertain** - Don't assume requirements
5. **Load appropriate contexts** - Read language/domain-specific context files as needed

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

## Session Management (Automatic + Optimized)

### Commands (All use Haiku model for 80% cost reduction)

**`/session-status`** - Check token usage, session health, get recommendations (~800 tokens)
**`/wrap-session`** - Save session context (compressed format, ~800-1k tokens)
**`/load-session [N]`** - Restore context (compressed display, ~600-800 tokens)

### Automatic Session Loading (MANDATORY)

**At the START of EVERY conversation in a project directory:**

1. Check if `.claude/sessions/index.json` exists
2. If exists: Automatically run `/load-session` (silent, compressed display)
3. Display 3-5 line recap to user
4. Load full context into agent memory (patterns, files, decisions)
5. Proceed with user request

**This is AUTOMATIC, not optional.** Sessions provide critical continuity context.

**Note:** Display mode auto-selects based on session size:
- Small sessions (< 10KB): Expanded view (all details)
- Large sessions (> 10KB): Compact view (summary + next steps)
- Multiple sessions: Always compact
- Override with `--full` or `--compact` flags

### Task Agent Context Passing

**Problem:** Task agents spawn without project context, waste 5k+ tokens re-reading files.

**Solution:** Use compressed context file before spawning Task agents.

**Workflow:**

1. **Check if context exists:**
   ```bash
   # If task-context.md exists and is recent (< 1 day old)
   if [ -f .claude/task-context.md ]; then
       # Read and use it
   else
       # Generate from latest session
       # Or run /wrap-session first
   fi
   ```

2. **Before spawning Task agent:**
   - Read `.claude/task-context.md` (if exists)
   - Include in Task agent prompt as additional context
   - **Example prompt:**
     ```
     Task: Explore authentication implementation

     Context from previous session:
     - Current focus: Refactoring auth module
     - Key pattern: Use AuthService singleton
     - Critical file: src/auth/AuthService.ts
     - Watch out: Token refresh logic has edge cases
     ```

3. **After Task agent completes:**
   - Context file can remain (useful for multiple Task agents)
   - Will be updated on next `/wrap-session`

**Token Savings:**
- Reading task-context.md: ~200-300 tokens
- Without context: Task agent reads 10-20 files = 5k+ tokens
- **Savings: ~4.7k-4.8k tokens per Task agent spawn** (95%+ reduction)

**When to generate:**
- Automatically created by `/wrap-session`
- Manually: Extract from latest session in `.claude/sessions/`
- Template: `~/.claude/templates/task-context.md`

### Auto-Wrap Triggers

**Token usage thresholds (monitored by `/session-status`):**
- 150k tokens: Strongly suggest `/wrap-session` with preview
- **Note:** Context overflow typically occurs at ~150k, not 200k limit

**When wrapping:**
- Compressed format captures only actionable context
- Max 5 items per array (patterns, tasks, files)
- Max 50 words per pattern
- Removes low-value fields (tool_usage, duration, etc.)
- Uses relative file paths
- Focus: continuity over documentation

### Workflow

1. **Start:** Sessions auto-load (you see 3-5 line recap)
2. **During:** Run `/session-status` to monitor token usage
3. **At 150k:** `/wrap-session` with preview of what will be captured
4. **New session:** Auto-loads previous context automatically

### Session Storage

- **Git repos:** `.claude/sessions/` in repo root
- **Worktrees:** Shared across all worktrees automatically
- **Non-git:** `{working_directory}/.claude/sessions/`
- **Dotfiles:** `~/.claude/sessions/` (global)

### Optimization Benefits

**Token savings per cycle:**
- Haiku model: 80% cost reduction
- Compressed schema: 75% size reduction
- Auto-load: Saves 5-10k tokens in context gathering
- Task context: Saves 5k tokens per Task agent spawn
- **Total: ~91% reduction** (10k → 1k tokens per cycle)

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

**Version:** 2.2 (Optimized Session Management)
**Last Updated:** 2026-01-19
**Token Budget:** ~4k (core only), ~7-10k (with typical contexts)