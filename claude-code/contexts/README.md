# Context Files Directory

This directory contains language and domain-specific context files that are loaded on-demand by Claude Code based on project requirements.

## Purpose

The modular context system reduces baseline token usage by separating universal principles (in `~/.claude/CLAUDE.md`) from language/domain-specific content. Claude Code loads only relevant contexts for each project.

## Available Contexts

- **python.md** (~2k tokens) - Python tooling (Ruff, mypy, pytest, uv), standards, patterns
- **php.md** (~700 tokens) - PHP standards (PSR-12, Composer, PHPUnit)
- **devops.md** (~3k tokens) - AWS, Terraform, IaC, infrastructure security, deployment
- **bash.md** (~3.7k tokens) - Shell scripting standards, error handling, patterns

## How It Works

### Automatic Detection
Claude Code can detect project type and load appropriate contexts:
- Python projects (has `.py`, `pyproject.toml`) → Load `python.md`
- PHP projects (has `.php`, `composer.json`) → Load `php.md`
- Terraform/IaC (has `.tf` files) → Load `devops.md`
- Shell scripts → Load `bash.md`

### Project-Level Configuration
Projects can specify required contexts in `.claude/CLAUDE.md`:

```markdown
## Context Requirements

**This project requires these contexts from `~/.claude/contexts/`:**
- ✅ **devops.md** - AWS, Terraform, infrastructure patterns
- ✅ **bash.md** - Shell scripting standards

**Skip:** python.md, php.md (not used in this project)
```

### Manual Loading
You can explicitly request contexts:
- "Load the Python context" → Reads `~/.claude/contexts/python.md`
- "I need DevOps guidance" → Reads `~/.claude/contexts/devops.md`

## Token Savings

**Before modularization:**
- Global CLAUDE.md: ~12k tokens (loaded every session)

**After modularization:**
- Core CLAUDE.md: ~4k tokens
- Python project: 4k (core) + 2k (python) = ~6k tokens
- DevOps project: 4k (core) + 3k (devops) + 3.7k (bash) = ~10.7k tokens
- Pure discussion: 4k (core only)

**Average savings:** 30-60% reduction in baseline token usage

## Adding New Contexts

To add a new context (e.g., Go, Rust, Docker):

1. Create the context file: `~/.claude/contexts/go.md`
2. Structure it similarly to existing contexts
3. Update core `CLAUDE.md` context loading documentation
4. Add detection rules if applicable

## Maintenance

- Keep contexts focused and concise
- Update version and last-modified date when changing
- Avoid duplication between core and contexts
- Universal principles stay in core CLAUDE.md only

---

**System Version:** 2.0
**Created:** 2025-11-27
**Location:** `~/.claude/contexts/`