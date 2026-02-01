# Python Development Context

This context is loaded when working on Python projects.

---

## Python Development Stack

### Formatting & Linting
- **Ruff** - All-in-one tool for formatting and linting
  - Replaces Black + flake8 + isort
  - Use default settings (line length: 88, Black-compatible)
  - Fast and modern

### Type Checking
- **mypy** - Type hint validation
  - Use for public APIs and complex functions
  - Works alongside Ruff without overlap

### Package Management
- **uv** - Modern Python package manager
  - Fast, reliable, Rust-based
  - Preferred over pip/poetry

### Testing
- **pytest** - Test framework
  - Descriptive test names
  - Arrange-Act-Assert pattern

### Philosophy
- **Consistency over personal preference** - Let tools decide style
- **Don't debate formatting** - Trust Ruff's defaults
- **Type hints** - Use for clarity and type safety

---

## Python Standards

- **Version:** Target latest stable (currently 3.13+)
- **Formatter:** Ruff (default settings)
- **Linter:** Ruff (replaces flake8, pylint)
- **Type Checker:** mypy
- **Testing:** pytest with TDD approach
- **Package Manager:** uv
- **Virtual Environments:** Always use venvs

---

## Module-Level Code
- ❌ **No executable code at module level**
- ✅ Only imports, constants, class/function definitions
- ✅ Avoid side effects on import

---

## Quick Reference

### Do:
✅ Write tests first (TDD with pytest)
✅ Use Ruff for Python formatting/linting
✅ Use mypy for type checking
✅ Always use virtual environments
✅ Use type hints for public APIs and complex functions
✅ Target Python 3.13+

### Don't:
❌ Override Ruff defaults without reason
❌ Execute code at module level
❌ Use pip/poetry (prefer uv)
❌ Skip tests for new code

---

## Environment & Best Practices
- User-level config: `~/.config/app_name/`
- Project-level config: `pyproject.toml`, `.app-name-rc`, etc.
- Shebangs: Only in entry points, not libraries
- Virtual envs: Always use project-specific venvs

---

**Context Version:** 1.0
**Last Updated:** 2025-11-27