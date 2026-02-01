# Bash Scripting Context

This context is loaded when working on Bash scripts and shell automation.

---

## Bash Standards

### Error Handling
- **Always use:** `set -e` - Exit on error
- **Strict mode:** `set -euo pipefail` for robust scripts
- **Error traps:** Implement error handling functions
```bash
set -euo pipefail

handle_error() {
    echo "ERROR: Failed at line $1" >&2
    exit 1
}

trap 'handle_error $LINENO' ERR
```

### Variable Handling
- **Quote variables** - Prevent word splitting: `"$variable"`
- **Default values** - Use `${VAR:-default}` pattern
- **Unset check** - Use `set -u` to catch unset variables

### Code Organization
- **Functions over inline** - Extract complex logic into functions
- **Comment complex logic** - Explain non-obvious behavior
- **Descriptive names** - Use clear function and variable names
- **Modular design** - Source common functions from libraries

---

## Script Structure

### Best Practices
```bash
#!/usr/bin/env bash
# Script description

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/var/log/script.log"

# Functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

main() {
    log "Starting script..."
    # Main logic here
}

# Entry point
main "$@"
```

### Logging
- **Timestamps** - Always include timestamps in logs
- **Log levels** - INFO, WARN, ERROR for clarity
- **Dual output** - Log to file and console when appropriate
```bash
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}
```

---

## Security Considerations

### Input Validation
- **Sanitize inputs** - Never trust user input
- **Command injection** - Avoid passing unsanitized input to commands
- **Path traversal** - Validate file paths

### Secrets
- **Never hardcode** - Use environment variables or secret managers
- **Avoid echo** - Don't log sensitive data
- **File permissions** - Secure credential files (600)

---

## Testing & Debugging

### Debugging
- **Verbose mode** - `set -x` for tracing execution
- **ShellCheck** - Use for static analysis (if available)
- **Test incrementally** - Build and test piece by piece

### Testing
- **Test edge cases** - Empty strings, missing files, etc.
- **Exit codes** - Check command exit codes explicitly
- **Idempotency** - Scripts should be safe to run multiple times

---

## Common Patterns

### Conditional Execution
```bash
# Guard clauses (preferred)
if [[ ! -f "$config_file" ]]; then
    echo "ERROR: Config file not found" >&2
    exit 1
fi

# Process file...
```

### Loops
```bash
# Iterate over files safely
while IFS= read -r -d '' file; do
    process "$file"
done < <(find . -name "*.txt" -print0)
```

### Function Return Values
```bash
# Return status codes, not strings
check_service() {
    if systemctl is-active --quiet "$1"; then
        return 0
    else
        return 1
    fi
}

if check_service "nginx"; then
    echo "Service running"
fi
```

---

## Quick Reference

### Do:
✅ Use `set -euo pipefail` for error handling
✅ Quote all variables ("$var")
✅ Extract complex logic into functions
✅ Add comments for non-obvious logic
✅ Log with timestamps
✅ Validate inputs and paths
✅ Check exit codes explicitly

### Don't:
❌ Ignore errors (omitting `set -e`)
❌ Leave variables unquoted
❌ Hardcode secrets
❌ Use `eval` without careful validation
❌ Nest complex logic inline
❌ Trust user input
❌ Log sensitive data

---

## Tools & Environment

### Shell
- **bash** - Primary shell
- **vim** - Quick edits

### Best Practices
- **Shebangs:** `#!/usr/bin/env bash` (portable)
- **Entry points only** - Scripts, not sourced libraries
- **Executable bit** - Set with `chmod +x`

---

**Context Version:** 1.0
**Last Updated:** 2025-11-27