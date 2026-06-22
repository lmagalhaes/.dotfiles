---
paths:
  - "**/*.sh"
  - "**/*.bash"
---

# Bash Scripting Standards

## Script Structure
```bash
#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

handle_error() { echo "ERROR: Failed at line $1" >&2; exit 1; }
trap 'handle_error $LINENO' ERR

main() {
    # logic here
}

main "$@"
```

## Rules
- Always `set -euo pipefail` — exit on error, unset vars, pipe failures
- Quote all variables: `"$var"`, not `$var`
- Default values: `${VAR:-default}`
- Extract complex logic into named functions
- Guard clauses at top; early exit on invalid state
- Never hardcode secrets — env vars or secret managers only
- Sanitize all user input before passing to commands
- Idempotent: safe to run multiple times

## Performance Tools (prefer over standard alternatives)
- `rg` over `grep`, `fd` over `find`, `bat` over `cat`, `eza` over `ls`
- `jq` for JSON, `yq` for YAML (not sed/awk)
- `pigz` over `gzip`, `pv` for pipe progress

## Before Committing
- Run `shellcheck` if available
- Verify idempotency manually or via tests
