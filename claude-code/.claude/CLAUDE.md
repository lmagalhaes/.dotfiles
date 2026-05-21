# Leandro Magalhães — Developer Preferences

**Role:** Sr Software Engineer / Jr-Mid DevOps
**Location:** Sydney, Australia (AEDT/AEST)
**Context:** Mix of personal projects and Workyard company work

---

## Code Quality

- Readability over clever code — be nice to your future self
- KISS — don't overcomplicate; logical structure flows naturally
- Extract complexity: named variables for multi-condition ifs, functions for complex blocks
- SOLID principles; design patterns when appropriate, not forced
- Only change relevant code — unnecessary changes = unnecessary risk

### Object Calisthenics (pragmatic OO)
- One level of indentation per method — extract early
- No else — guard clauses and early returns instead
- No abbreviations — full, meaningful names
- Small classes and short methods
- Wrap primitives for domain concepts (Email, Money) when it clarifies intent

---

## Testing

- TDD: write test first, minimal code to pass, refactor with confidence
- All new code needs tests; exceptions: trivial getters, obvious one-liners
- Test behavior, not implementation; descriptive names; one assertion per test

---

## Communication

- Balance detail with brevity — explain once, thoroughly
- Show code examples when helpful; skip for trivial changes
- Explain trade-offs unless trivial; ask when genuinely unclear
- Avoid: apologies, filler phrases ("Let me help you with that"), over-explanation
- More reading = more tiring. Be efficient with words.

---

## Security

- Never commit secrets — env vars, secret managers, keychains only
- Parameterized queries (no SQL injection), sanitize output (no XSS), validate paths
- Never log PII, passwords, or tokens
- Principle of least privilege; review dependencies

---

## Tool Preferences (Bash)

Prefer Claude tools (Read, Grep, Glob) over Bash when available.

When Bash is needed, prefer these over standard equivalents:
- `rg` over grep — faster, `.gitignore`-aware, auto no-color
- `fd` over find — cleaner path output, saner defaults
- `jq` for JSON, `yq` for YAML — filter/extract instead of dumping raw content
- `duf` over df, `pigz` over gzip, `pv` for progress

Human-only tools (presentation value only, never use in Bash tool calls):
- `bat` (use `cat` instead), `eza` (use `ls`), `delta` (use `git --no-pager diff`)

---

## Agent Behavior

- Default scope: current working directory only, unless explicitly asked broader
- Read files in parallel upfront — never serial one-by-one
- Spawn Explore agents for searches spanning 10+ attempts
- Suggest improvements related to current task only; ask before major refactors
- No AI co-author signatures in commits

@RTK.md
