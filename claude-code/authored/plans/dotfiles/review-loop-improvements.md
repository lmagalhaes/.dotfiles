# review-loop Skill — Improvements Plan

## Status

Prioritized backlog. Implement in order unless a dependency or real-world usage changes the sequence.

---

## Items

### ~~Priority 0. Use different models for different tasks~~ ✓
- Route each step to the cheapest model that preserves quality.
- Step B (parse findings): use a small structured-extraction model if the fallback LLM path is needed.
- Step E (fix findings): keep the stronger coding model for code changes.
- Verification pass: optionally use a stricter model for the final clean pass if that improves signal.
- Expose focused overrides only where they add real operator value; avoid turning model routing into a broad configuration surface too early.

### ~~1. Deterministic parser with LLM fallback~~ ✓
- Add a parser script for `codex review` output grounded in the captured golden samples.
- Keep the current LLM parsing path only as a fallback when the output is ambiguous or the format changes.
- Treat the parser as the primary contract for Step B so the loop does not depend on prompt parsing for normal runs.
- Save parser failures explicitly so output-format drift is easy to diagnose.

### ~~2. Per-run artifact storage~~ ✓
- Save each round's artifacts under `.claude/review-loop/<branch>/<run-timestamp>/`.
- Store at minimum:
  - `raw.txt` — raw `codex review` stdout
  - `parsed.json` — structured parse result
  - `round-N.json` — round summary
  - `final.json` — final loop outcome
- This makes the loop auditable, debuggable, and replayable.

### 3. Test hook after fixes
- Add an optional `--test-cmd <command>` hook.
- Run it after any round that changed files, or after every fixing round if that proves simpler.
- If the test command fails, stop the loop and report clearly instead of continuing to mutate the branch.

### ~~4. Stuck-loop detection~~ ✓
- Detect findings that recur across consecutive rounds with the same or nearly the same file, title, and location.
- Mark them as likely unresolvable by auto-fix instead of spending more iterations on them.
- Surface these explicitly in the final report as manual follow-up items.

### 5. Measure cost and time
- Record wall-clock time per round and total run time.
- Record practical cost proxies:
  - reviewer invocations
  - agent spawns
  - input/output payload sizes
- Include these metrics in stored round and final reports.
- Use `history.jsonl` only for post-hoc deeper analysis, not as a runtime dependency.

### 6. Tighten skill structure
- Keep `SKILL.md` focused on workflow, decision points, and stop conditions.
- Move detailed parsing edge cases and output-format quirks into the parser script and reference docs.
- Reduce duplication between `SKILL.md` and `references/output_format.md` so behavior changes live in one place.

### 7. Controlled operator features
- ~~**Dry-run mode** (`--dry-run`) — preview findings without applying fixes~~ ✓
- **Priority filter** (`--min-priority P2`) — skip lower-severity findings when needed
- **Skip-file list** (`--exclude`) — ignore generated files, vendored code, or intentional legacy areas

### 8. Reviewer abstraction
- Add `--reviewer <command>` and adapter scripts only after the parsing and reporting contract is stable.
- Avoid broadening the failure surface before the single-reviewer path is hardened.

### 9. Branch-intent context for review
- Add an optional way to pass a short branch/problem statement into `codex review` on the initial pass and subsequent rounds.
- Keep the context structured and behavior-level:
  - problem being solved
  - intended behavior after the change
  - explicit non-goals
  - invariants that must still hold
- Avoid implementation advice or "ignore this finding" language so the reviewer is informed without being steered toward false negatives.
- Preserve the existing skipped-finding rejection context as a separate block, and define how both context sources are combined for later rounds.
- Measure whether this reduces false positives on intentional behavior changes, migrations, and refactors before making it the default path.

---

## Recommended Order

0. Use different models for different tasks
1. Deterministic parser with LLM fallback
2. Per-run artifact storage
3. Test hook after fixes
4. Stuck-loop detection
5. Measure cost and time
6. Tighten skill structure
7. Controlled operator features
8. Reviewer abstraction
9. Branch-intent context for review
