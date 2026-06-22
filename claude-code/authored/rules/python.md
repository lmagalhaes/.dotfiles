---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
  - "**/setup.py"
  - "**/setup.cfg"
---

# Python Standards

## Toolchain
- **Ruff** — formatting and linting (replaces Black + flake8 + isort); use default settings
- **mypy** — type checking for public APIs and complex functions
- **uv** — package manager (prefer over pip/poetry)
- **pytest** — test framework; TDD approach
- Target Python 3.13+; always use virtual environments

## Code Style
- Let Ruff decide formatting — don't override defaults without reason
- Type hints on all public function signatures
- No executable code at module level (only imports, constants, definitions)
- Guard clauses over nested ifs; early return on invalid state

## Testing
- TDD: write test first, minimal code to pass, refactor with confidence
- Descriptive test names: test_it_does_x_when_y
- One assertion per test when reasonable
- Tests in tests/ mirroring src/ structure

## Environment
- User-level config: ~/.config/app_name/
- Project-level config: pyproject.toml
- Shebangs (#!/usr/bin/env python3) only in entry points, not libraries
- Always use project-specific virtual environments (uv venv)

## Before Committing
1. `ruff format .` — auto-format
2. `ruff check .` — lint (fix with --fix)
3. `mypy src/` — type check
4. `pytest` — all tests pass
