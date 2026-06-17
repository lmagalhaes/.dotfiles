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
/<skill-name> --base main --max-iterations 5
```

where `<skill-name>` is the `name:` value from this file's frontmatter.

Defaults: `--base main`, `--max-iterations 3`

---

## Pre-flight checks

Before starting the loop:

1. Warn if the current branch name contains the skill's own name (the `name:` value from
   this file's frontmatter) — the skill is reviewing itself, which can cause confusing
   feedback loops. Ask the user to confirm before continuing.

2. Parse `$ARGUMENTS`:
   - `--base <branch>` → base branch for the diff (default: `main`)
   - `--max-iterations <N>` → max loop iterations (default: `3`)

3. Verify `codex` is on PATH: `which codex` — if not found, stop with:
   > `codex not found on PATH. Install it and retry.`

4. No untracked-file warning needed — `--uncommitted` includes staged, unstaged, and
   untracked changes, so all worktree content is visible to codex review.

---

## Loop

Run this loop up to `--max-iterations` times. Track the current iteration number (1-based).

### Step A — Run codex review

```bash
# All rounds — --uncommitted ensures staged/unstaged edits to tracked files
# are always included, whether they existed before the loop or were applied
# by a previous round's fixes.
codex review --base <base-branch> --uncommitted
```

Capture full stdout and the exit code.

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

### Step B — Parse findings via LLM agent

Spawn an Agent with this prompt (substitute actual stdout):

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

Use a structured output schema matching the JSON shape above.

### Step C — Handle status

**If `status == "error"` (check this first):**
- Stop the loop immediately. Report:
  > `⚠ codex review produced no review block — the tool may have hit a startup or auth failure. Check the output and retry.`

**If `base_branch_fallback == true`:**
- Stop the loop immediately. Report:
  > `⚠ codex could not resolve base branch '<base-branch>' and fell back to origin/main. The review was not against the requested base — aborting to avoid false results. Check the branch name and retry.`
- Do NOT treat the review as clean or proceed with fixing, even if `status == "clean"`.

**If `status == "clean"` (and no fallback):**
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

### Step E — Fix introduced findings

For each `introduced` finding (in priority order, P1 first):

1. Read the relevant file around the affected lines.
2. Apply a fix using Edit/Write. No need to stage new files — `--uncommitted` makes
   all worktree changes (including untracked new files) visible to the next round.
3. Briefly explain what you changed and why (one sentence).
4. Do NOT commit — fixes accumulate; the user commits.
5. After editing a file, **skip all remaining findings in that same file** for this round.
   Line numbers from the original review are now stale. The next round's codex pass will
   re-report any unresolved issues in that file with updated line numbers.

If a finding is ambiguous (you are unsure how to fix it safely), skip it and note it in the
round report.

### Step F — Round report

After fixing, print a round report (JSON-shaped, for AI consumption):

```json
{
  "round": <N>,
  "total_findings": <count>,
  "introduced": <count>,
  "pre_existing": <count>,
  "fixed": <count>,
  "skipped": <count>,
  "skipped_reasons": ["finding title: reason"],
  "remaining_introduced": <count>
}
```

If `remaining_introduced == 0` and iterations remain and no verification pass has been run
yet this loop, do **not** stop yet — mark that the verification pass has been used and run
one more iteration. This pass counts against `--max-iterations`. On it:
- `status == "clean"` → stop (truly clean)
- All findings are `pre_existing` → stop (only out-of-scope issues remain)
- Any finding is `introduced` → clear the verification-pass flag and continue fixing

After a verification pass, if `remaining_introduced == 0`, stop — do not schedule a second
verification pass. Only a new round of introduced findings clears the flag and resumes normal
iteration.

If no iterations remain when `remaining_introduced == 0`, stop without the verification
pass and note in the final report that the clean-pass was skipped due to the iteration
limit.

If `remaining_introduced > 0` and more iterations remain, go back to Step A with any
rejection context (see below).

### Rejection context for next round

If any findings were skipped (ambiguous fix), collect all of them into a single rejection
note and pass it to the next `codex review` invocation via stdin:

```bash
codex review --base <base-branch> --uncommitted - <<'EOF'
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
Review loop complete — <N> round(s)

Outcome: <clean | findings remain>
Fixed: <total fixed across all rounds>
Pre-existing (not fixed): <count> — out of scope for this branch
Remaining unfixed introduced: <count>

<If remaining > 0:>
Remaining findings (introduced by this branch, not fixed):
- [P1] <title> — <filepath>:<line_start>-<line_end>
  <description>

Next steps:
- Run this skill again to attempt another pass
- Or fix manually and commit
```

If the loop hit the iteration limit without reaching clean, say so explicitly:
> `Stopped after <N> iterations (limit reached). <M> introduced finding(s) remain.`

---

## Reference

Output format details: `references/output_format.md`  
Golden samples: `references/samples/`
