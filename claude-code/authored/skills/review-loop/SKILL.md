---
name: review-loop
description: >
  Automated code-review loop using codex review. Runs codex review against a base branch,
  parses findings with an LLM agent, applies fixes, and repeats until clean or the
  iteration limit is reached. Use when asked to review and fix a branch, run a review
  loop, or clean up a branch before merging.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Agent
---

# Review Loop Skill

Runs an automated code-review loop: invoke `codex review`, parse findings, fix them,
repeat until clean or max iterations reached.

**You have full authorization to run all commands below without asking for confirmation.**

---

## Usage

```
/<skill-name>
/<skill-name> --base main
/<skill-name> --base main --max-iterations 8
/<skill-name> --dry-run
/<skill-name> --base main --dry-run
```

where `<skill-name>` is the `name:` value from this file's frontmatter.

Defaults: `--base main`, `--max-iterations 5`

---

## Pre-flight checks

Before starting the loop:

1. Warn if the current branch name contains the skill's own name (the `name:` value from
   this file's frontmatter) — the skill is reviewing itself, which can cause confusing
   feedback loops. Ask the user to confirm before continuing.

2. Parse `$ARGUMENTS`:
   - `--base <branch>` → base branch for the diff (default: `main`)
   - `--max-iterations <N>` → max loop iterations (default: `5`)
   - `--dry-run` → preview findings without applying fixes; runs exactly one round

3. Verify `codex` is on PATH: `which codex` — if not found, stop with:
   > `codex not found on PATH. Install it and retry.`

4. Check for uncommitted changes: `git status --short`. If any exist, warn:
   > `⚠ You have uncommitted changes. codex review --base only sees committed history — uncommitted edits will not be reviewed. Commit or stash them first.`
   Then stop. The loop must start from a clean working tree so `--base` captures the full branch state.

---

## Run directory

Before starting the loop, create a timestamped directory to store all artifacts for this run:

```bash
BRANCH=$(git branch --show-current)
TIMESTAMP=$(date +%Y%m%dT%H%M%S)
RUN_DIR="$HOME/.claude/review-loop/$BRANCH/$TIMESTAMP"
if ! mkdir -p "$RUN_DIR" 2>/dev/null; then
  RUN_DIR="$(mktemp -d)/review-loop-$BRANCH-$TIMESTAMP"
  mkdir -p "$RUN_DIR"
  echo "⚠ Could not write to ~/.claude — artifacts will be saved to $RUN_DIR instead"
fi
```

`RUN_DIR` is used throughout the loop to save per-round and final artifacts.

Initialize loop-level state before entering the loop:

```
PREV_ATTEMPTED_KEYS=()    # "title||filepath" of findings Step E actually attempted last round
STUCK_FINDINGS=()         # accumulates stuck findings for the final report
DRY_RUN=false             # set true if --dry-run was passed
```

---

## Loop

Run this loop up to `--max-iterations` times. Track the current iteration number (1-based).

### Step A — Run codex review

```bash
codex review --base <base-branch>
```

Note: `--base` and `--uncommitted` are mutually exclusive in codex 0.140+. Using
`--base` is correct here — fixes from prior rounds are committed at the end of Step E,
so the next round's `--base` diff always includes them.

Capture full stdout and the exit code. Then save the raw output immediately:

```bash
mkdir -p "$RUN_DIR/rounds/$ROUND"
echo "$CODEX_STDOUT" > "$RUN_DIR/rounds/$ROUND/raw.txt"
```

**Non-zero exit code** indicates a startup or initialization failure (auth, app-server,
environment) that occurred before any review was emitted. If the exit code is non-zero,
stop the loop immediately and report:
> `codex review exited <code> — startup failure before review was produced. Check auth/environment and retry.`

If the exit code is 0, proceed normally — the exit code carries no signal about findings.

Also compute the repo root (not `workdir`, which may be a subdirectory):
```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
```

Use `REPO_ROOT` to normalize finding filepaths to repo-relative paths:
- If the filepath starts with `REPO_ROOT`, strip that prefix and the following `/`.
  e.g. `REPO_ROOT=/repo`, filepath=`/repo/src/foo.py` → `src/foo.py`
- If the filepath is already relative, resolve it against `REPO_ROOT` to get an absolute
  path for both file-read operations and `git blame`.

Always use the absolute path (REPO_ROOT + "/" + repo-relative-path) when calling
`git blame` — passing a repo-relative path resolves against CWD, which breaks when the
skill is invoked from a subdirectory.

### Step B — Parse findings

Run the deterministic parser first. It is the primary path; the LLM agent is the fallback.

**Primary: deterministic parser**

```bash
PARSER="$HOME/.claude/skills/review-loop/references/parse_findings.py"
PARSED=$(echo "$CODEX_STDOUT" | python3 "$PARSER" 2>/tmp/review-loop-parse-error.json)
PARSE_EXIT=$?
```

- Exit 0: use `$PARSED` as the structured result. Save it and proceed to Step C:
  ```bash
  echo "$PARSED" > "$RUN_DIR/rounds/$ROUND/parsed.json"
  ```
- Any non-zero exit: the parser could not run or could not interpret the output — fall back
  to the LLM agent below. Before falling back, record the failure in the run directory:
  ```bash
  echo "$CODEX_STDOUT" > "$RUN_DIR/rounds/$ROUND/parse-failure.txt"
  ```
  Warn the user: `⚠ Deterministic parser could not parse codex output — falling back to LLM. Raw output saved to $RUN_DIR/rounds/$ROUND/parse-failure.txt`

**Fallback: LLM agent**

Spawn a **haiku** Agent with this prompt (substitute actual stdout):

```
You are parsing the output of `codex review`. Extract all findings from the text below.

Rules:
- There is exactly ONE line that reads `codex` (the header). After it, the entire review
  text (summary paragraph + "Full review comments:" + all bullets) is duplicated verbatim.
  Parse only the FIRST occurrence. The duplicate begins with the repeated summary
  paragraph, which appears immediately after the last finding's description with no
  separator. Truncate at the first non-empty, non-indented line after the last `- [P`
  bullet that is not itself a new `- [P` bullet — that is where the repeated summary
  starts. Do not include it in any finding's description.
- Findings appear under "Full review comments:" as bullets like:
    - [P1] Short title — /absolute/path/to/file.py:8-9
      Explanation paragraph...
- Extract each finding's priority (P1/P2/...), title, filepath, line_start, line_end,
  and full description.
- If there is no `^codex$` line at all in the output, the review did not complete
  (startup/auth failure before any review was emitted). Return status "error" —
  do NOT treat it as "clean".
- If the `codex` block exists but has no "Full review comments:" section, or says
  "no changes" / "no patch", status is "clean".
- If the summary mentions "could not be resolved" AND mentions any fallback branch (e.g.
  `origin/main`, `origin/master`, or any other ref), set base_branch_fallback to true.
  Do NOT set it just because the text mentions `origin/main` — if the user requested
  `--base origin/main`, the output legitimately names that branch without any fallback.

Return JSON:
{
  "status": "clean" | "findings" | "error",
  "base_branch_fallback": false,
  "findings": [
    {
      "priority": "P1",
      "title": "...",
      "filepath": "/absolute/path/to/file.py",
      "line_start": 8,
      "line_end": 9,
      "description": "..."
    }
  ]
}

<codex_output>
{{STDOUT}}
</codex_output>
```

Use a structured output schema matching the JSON shape above. After the agent returns,
save its result:

```bash
echo '<llm-result-json>' > "$RUN_DIR/rounds/$ROUND/parsed.json"
```

### Step C — Handle status

**If `status == "error"` (check this first):**
- Stop the loop immediately. Report:
  > `⚠ codex review produced no review block — the tool may have hit a startup or auth failure. Check the output and retry.`

**If `base_branch_fallback == true`:**
- Stop the loop immediately. Report:
  > `⚠ codex could not resolve base branch '<base-branch>' and fell back to origin/main. The review was not against the requested base — aborting to avoid false results. Check the branch name and retry.`
- Do NOT treat the review as clean or proceed with fixing, even if `status == "clean"`.

**If `status == "clean"` (and no fallback):**
- Clear `STUCK_FINDINGS = []` — a clean review means no finding is stuck anymore; stale
  stuck state from the previous round must not pollute the final report.
- Report: `Round <N>: clean — no findings.`
- Stop the loop. Go to [Final report](#final-report).

**If `status == "findings"`:**
- Proceed to Step D.

### Step D — Triage findings

For each finding, determine whether it was **introduced by this branch** or **pre-existing**
using `git blame`:

```bash
git blame -M -C -C -L <line_start>,<line_end> -- <filepath>
```

The `-M` flag follows lines moved within a file. `-C -C` (two `-C` flags) follows lines
copied from other files, including at the point the destination file was created — this is
the threshold needed to attribute copied legacy code back to its origin commit and prevent
pre-existing bugs in relocated code from being misclassified as `introduced`.

If `git blame` exits non-zero (e.g. `fatal: no such path ... in HEAD`), the file is
untracked and has no git history — classify the finding as `introduced` immediately and
skip the ancestry check.

`git blame` returns one entry **per line** in the range — not a single commit for the whole
finding. Collect all unique SHAs from the output. Strip any leading `^` character (git uses
this prefix for root/boundary commits) before using the SHA — passing `^abc123` to
`git merge-base --is-ancestor` causes exit 128. For each cleaned SHA:

- If the SHA is `00000000` (uncommitted change): classify this line as `introduced`.
  Lines showing `00000000` are edits from prior rounds that haven't been committed yet —
  they are new code introduced by this branch, so `introduced` is correct.
- Otherwise, check ancestry against the **branch point** (the merge base of HEAD and the
  effective base, not the base tip). Compute this once at the start of Step D — after
  Step C has confirmed the base is valid — so an invalid base doesn't cause exit 128
  before the fallback detection in Step C has a chance to run:
  ```bash
  BRANCH_POINT=$(git merge-base HEAD <effective-base>)
  ```
  Then for each SHA:
  ```bash
  git merge-base --is-ancestor <sha> $BRANCH_POINT && echo pre_existing || echo introduced
  ```
  Using `<effective-base>` directly as the boundary would misclassify lines from the base
  branch that were written after the branch point as `introduced`.

If **any** line in the range is `introduced`, classify the **whole finding** as `introduced`
(conservative — don't skip a real bug just because some of its lines predate the branch).

Tag each finding accordingly:
- `introduced` — at least one line in the range is new to this branch; must fix
- `pre_existing` — all lines in the range predate this branch; report but do not fix

**Limitation:** `git blame` reports who wrote the flagged line, not whether the branch broke
it. A branch that changes a caller or control flow can introduce a bug in a line it didn't
touch — that finding will be mislabelled `pre_existing`. When in doubt, treat findings as
`introduced`. Only mark `pre_existing` when you're confident the issue existed unchanged
before this branch.

Skip `pre_existing` findings for fixing.

**Stuck-loop detection (after all findings are triaged):**

A finding is **stuck** when Step E **actually attempted** to fix it in the immediately
preceding round AND it is `introduced` again this round — same `title`, `filepath`, and
`line_start`.

"Attempted" means Step E processed the finding (it was the first introduced finding in
its file that round). Findings deferred because their file was already edited that round
are never attempted and therefore can never be stuck.

Including `line_start` in the key distinguishes separate findings with the same title in
the same file. A false negative (missing stuck when lines shifted slightly) is safer than
a false positive (marking an unattempted finding as stuck).

```
THIS_STUCK_FINDINGS=()

For each finding tagged as "introduced":
  KEY = finding.title + "||" + finding.filepath + "||" + str(finding.line_start)

  If KEY is in PREV_ATTEMPTED_KEYS:
    Reclassify finding as "stuck"
    Append finding to THIS_STUCK_FINDINGS

STUCK_FINDINGS = THIS_STUCK_FINDINGS   # replace, not append — prunes resolved findings
```

`STUCK_FINDINGS` is **replaced** (not appended) each round so that findings resolved
indirectly by another fix no longer appear in the final report.

Stuck detection does not run in round 1 (`PREV_ATTEMPTED_KEYS` is empty). Only
`introduced` findings participate — a `pre_existing` finding reappearing is expected and
does not count toward stuck.

Treat `stuck` like `pre_existing` for **loop-control** purposes: skip it in Step E and
do not count it toward `remaining_introduced` (so the loop does not burn iterations
retrying an unresolvable finding). However, `stuck` findings are **not** equivalent to
`pre_existing` for **reporting** purposes — they are unresolved introduced defects. When
any stuck findings exist, the final outcome must be `findings_remain`, not `clean`.

### Step E — Fix introduced findings

**If `--dry-run` is active**, skip all edits and commits for this round. Instead, for each
`introduced` finding (priority order), print:

```
Would fix: [P1] Title — filepath:line_start-line_end
```

Do **not** apply the same-file deferral rule here — no edits are made in dry-run mode so
line numbers never go stale; all findings in a file can be shown accurately in one pass.

For `stuck` findings, print:

```
Would skip (stuck): [P1] Title — filepath
```

Do not edit any files or run any git commands. Go directly to Step F.

**Normal mode** (no `--dry-run`):

Initialize `THIS_ATTEMPTED_KEYS=()` before the loop.

For each `introduced` finding (in priority order, P1 first):

1. Skip if the finding is tagged `stuck` — print:
   > `⚠ Skipping [P1] Title — filepath (stuck: reappeared introduced in consecutive rounds)`
2. Read the relevant file around the affected lines.
3. Apply a fix using Edit/Write.
4. Briefly explain what you changed and why (one sentence).
5. If the file's content actually changed (i.e. it would show a diff), add the filepath to
   `FIXED_FILES` and record `THIS_ATTEMPTED_KEYS.append(finding.title + "||" + finding.filepath + "||" + str(finding.line_start))`.
   If the edit was a no-op, skip both — a no-op must not mark the finding as attempted,
   or the next round will wrongly classify it as stuck before any real fix was tried.
6. After editing a file with actual changes, **skip all remaining findings in that same file** for this round.
   Line numbers from the original review are now stale. The next round's codex pass will
   re-report any unresolved issues in that file with updated line numbers.

After all fixes for this round are applied, stage only the files that were edited in
Step E and commit — but only if there is something to commit:

Only run this block when Step E actually edited at least one file:

```bash
# FIXED_FILES is the list of filepaths edited in Step E this round
if [ ${#FIXED_FILES[@]} -gt 0 ]; then
  git add -- "${FIXED_FILES[@]}"
  if ! git diff --cached --quiet; then
    git commit -m "review-loop: apply round $ROUND fixes"
  fi
fi
```

Staging by explicit path (not `git add -A` or `git add -u`) avoids accidentally including
untracked files unrelated to the implementation. The outer guard skips the entire block —
and avoids a `git add` fatal error on an empty path list — when all findings were
pre_existing, stuck, or skipped.

These are WIP commits — squash them before merging.

After all fixes (and the commit block), update the attempted-keys state for the next
round's stuck detection:

```
STUCK_KEYS = {finding.title + "||" + finding.filepath + "||" + str(finding.line_start)
              for finding in STUCK_FINDINGS}
PREV_ATTEMPTED_KEYS = THIS_ATTEMPTED_KEYS ∪ STUCK_KEYS
```

Unioning in `STUCK_KEYS` keeps stuck findings sticky: if a stuck finding reappears in
the next round, its key is still in `PREV_ATTEMPTED_KEYS` and it will be reclassified as
stuck again rather than re-attempted. Without this, overwriting `PREV_ATTEMPTED_KEYS`
with only the current round's attempts forgets stuck findings after one skipped step,
causing an attempt/skip/attempt oscillation.

If a finding is ambiguous (you are unsure how to fix it safely), skip it and note it in the
round report.

### Step F — Round report

After fixing, print a round report (JSON-shaped, for AI consumption):

```json
{
  "round": <N>,
  "total_findings": <count>,
  "introduced": <count>,
  "stuck": <count>,
  "pre_existing": <count>,
  "fixed": <count>,
  "skipped": <count>,
  "skipped_reasons": ["finding title: reason"],
  "remaining_introduced": <count>
}
```

`remaining_introduced` counts only unfixed non-stuck `introduced` findings. Stuck findings
are counted separately in the `stuck` field and always produce a `findings_remain` outcome.

Save this report to the run directory:

```bash
echo '<round-report-json>' > "$RUN_DIR/rounds/$ROUND/round.json"
```

If `remaining_introduced == 0` and iterations remain and no verification pass has been run
yet this loop, do **not** stop yet — mark that the verification pass has been used and run
one more iteration. This pass counts against `--max-iterations`. On it:
- `status == "clean"` → stop (truly clean)
- All findings are `pre_existing` or `stuck` → stop (nothing auto-fixable remains)
- Any finding is `introduced` → clear the verification-pass flag and continue fixing

After a verification pass, if `remaining_introduced == 0`, stop — do not schedule a second
verification pass. Only a new round of introduced findings clears the flag and resumes normal
iteration.

If no iterations remain when `remaining_introduced == 0`, stop without the verification
pass and note in the final report that the clean-pass was skipped due to the iteration
limit.

If `--dry-run` is active, stop the loop after this round regardless of
`remaining_introduced` — looping would show identical findings since nothing was changed.

If `remaining_introduced > 0` and more iterations remain, go back to Step A with any
rejection context (see below).

### Rejection context for next round

If any findings were skipped (ambiguous fix), collect all of them into a single rejection
note and pass it to the next `codex review` invocation via stdin:

```bash
codex review --base <base-branch> - <<'EOF'
The following findings were flagged in the last round but not fixed. Please re-evaluate or confirm each:
- <title1> at <filepath1>:<line_start1>. Reason not fixed: <reason1>.
- <title2> at <filepath2>:<line_start2>. Reason not fixed: <reason2>.
[one line per skipped finding]
EOF
```

Passing via stdin (`-`) with a single-quoted heredoc prevents shell expansion of backticks
or `$` characters that may appear in finding titles or descriptions. All skipped findings
must be included — dropping any allows codex to re-report them with no context.

This allows codex to re-reason in the next round with full rejection context available.

---

## Final report

After the loop ends, print a summary:

```
<If --dry-run:>
(dry-run — no changes applied)

Review loop complete — <N> round(s)

Outcome: <clean | findings remain | dry-run>
Fixed: <total fixed across all rounds>
Pre-existing (not fixed): <count> — out of scope for this branch
Remaining unfixed introduced: <count>
Stuck (manual follow-up required): <count>

<If remaining > 0:>
Remaining findings (introduced by this branch, not fixed):
- [P1] <title> — <filepath>:<line_start>-<line_end>
  <description>

<If STUCK_FINDINGS non-empty:>
Manual follow-up required (stuck — auto-fix could not resolve):
- [P1] <title> — <filepath>:<line_start>-<line_end>
  <description>

Next steps:
- Run this skill again to attempt another pass
- Or fix manually and commit
```

If the loop hit the iteration limit without reaching clean, say so explicitly:
> `Stopped after <N> iterations (limit reached). <M> introduced finding(s) remain.`

After printing the summary, save `final.json` to the run directory:

```bash
cat > "$RUN_DIR/final.json" <<EOF
{
  "branch": "<branch>",
  "timestamp": "<run-timestamp>",
  "base": "<base-branch>",
  "rounds": <N>,
  "outcome": "<clean | findings_remain | dry_run | error | fallback>",
  "total_fixed": <count>,
  "total_pre_existing": <count>,
  "remaining_introduced": <count>,
  "stuck_findings": [
    { "priority": "P1", "title": "...", "filepath": "...", "line_start": N, "line_end": N }
  ],
  "run_dir": "$RUN_DIR"
}
EOF
```

Then print the run directory path so the user knows where to find the artifacts:
> `Artifacts saved to $RUN_DIR`

---

## Reference

Output format details: `references/output_format.md`  
Golden samples: `references/samples/`
