# codex review — Output Format Reference

Derived from golden samples in `references/samples/`. All observations are ground-truth from
real invocations of `codex review` v0.140.0.

---

## Exit code

**0 for all review outcomes.** Within a successful run:

- Clean review (no findings) → exit 0
- Review with findings → exit 0
- Nonexistent base branch → exit 0 (falls back silently to `origin/main`)
- Shell errors inside codex (snapshot failures, pyenv warnings) → exit 0

**Non-zero exit** indicates a startup or initialization failure (auth, app-server, environment
setup) that aborted the process before any review block was emitted. Treat non-zero as a
hard stop — do not attempt to parse the output.

**In the loop:** check exit code first. If non-zero, abort and report a startup failure.
If 0, proceed to parse — exit code carries no signal about findings.

---

## Overall structure

```
OpenAI Codex v<version>
--------
workdir: <path>
model: <model>
provider: <provider>
approval: <policy>
sandbox: <policy>
reasoning effort: <level>
reasoning summaries: <level>
session id: <uuid>
--------
user
changes against '<base-branch>'
<ERROR lines — noise>

exec
<shell command>
 succeeded/exited in <Nms>:
<stdout/stderr of the command>

[... more exec blocks ...]

codex
<review summary paragraph>

Full review comments:

- [P1] <short title> — <filepath>:<line-range>
  <multi-line explanation, indented>

- [P2] <short title> — <filepath>:<line-range>
  <multi-line explanation, indented>
<entire codex block repeats here — see Duplication below>
```

---

## Duplication quirk

The entire `codex` block (summary paragraph + "Full review comments:" + all findings) is
printed **twice** in a row. This is always present regardless of outcome. When parsing,
extract only the **first occurrence** of the codex block and discard the duplicate.

Detection: the duplicate begins with the repeated **summary paragraph**, which appears
immediately after the last finding's description (no blank line separator). The second
`Full review comments:` header comes after that repeated summary. So use the second
`Full review comments:` as a backstop, but the real truncation point is the first
non-empty, non-indented line after the last `- [P` bullet that is not itself a new
`- [P` bullet — that line starts the repeated summary. Discard from there onward.

---

## Noise lines (always present, always ignorable)

Lines matching these patterns appear in every run and carry no signal:

```
ERROR codex_core::shell_snapshot: Shell snapshot validation failed: ...
pyenv: cannot rehash: ...
```

---

## Section markers

| Marker | Meaning |
|---|---|
| `^--------$` | Separator — between header and body |
| `^user$` | Start of user input section |
| `^exec$` | Start of a shell command block |
| `^codex$` | Start of codex response (appears once; the body is duplicated, not the marker) |
| `^Full review comments:$` | Start of structured findings list |

---

## Finding format

Each finding is a bullet under "Full review comments:":

```
- [<Priority>] <Short title> — <filepath>:<line-range>
  <Explanation paragraph, one or more lines, indented with two spaces>
```

- **Priority labels:** `P1`, `P2`, `P3`, … (higher number = lower severity)
  - P1 = critical bug or security issue
  - P2 = important hygiene or correctness concern
  - P3 = minor issue
- **filepath:** absolute path (e.g. `/Users/.../sample_issues.py`) or repo-relative path
  (e.g. `sample_issues.py`). Use the repo root (`git rev-parse --show-toplevel`), not
  `workdir` (which may be a subdirectory), to normalize paths: if the path starts with the
  repo root, keep it as-is; if already relative, resolve against the repo root to get an
  absolute path. Always pass the **absolute path** to `git blame` — relative paths fail
  when the skill is invoked from a subdirectory.
- **line-range:** `N-N` (range) or `N-N` single line shown as `21-21`
- **Separator:** ` — ` (space, em-dash, space) between title and location

---

## Detecting review outcome

Since exit code is always 0, outcome must be inferred from text content:

| Outcome | Signal |
|---|---|
| **Clean** | No "Full review comments:" section, OR codex block says "no changes" / "no patch" |
| **Has findings** | "Full review comments:" section present with one or more `- [P` bullets |
| **Branch fallback** | codex summary contains "could not be resolved" AND mentions `origin/main` as the fallback |

Clean sample signal:
> `` `git diff <sha>` produced no changes in this worktree ``

Fallback signal:
> `The requested base branch could not be resolved, so I reviewed the branch delta against origin/main`

---

## exec blocks

Codex runs several git commands internally and logs them. These are informational only.
A command that `exited 128` (e.g. `fatal: no such branch`) is a codex internal failure;
codex recovers from it and continues — it is **not** a signal to abort.

---

## What to extract for each finding

When parsing the codex block into structured data:

```json
{
  "priority": "P1",
  "title": "Avoid reading value for inactive items",
  "filepath": "/Users/.../sample_issues.py",
  "line_start": 8,
  "line_end": 9,
  "description": "Full explanation text..."
}
```

- Strip the repo root prefix to get a repo-relative path (use `git rev-parse --show-toplevel`, not `workdir`)
- `line_start` and `line_end` come from the `N-N` range; if single line `21-21`, both are the same value
- `description` is the indented paragraph(s) that follow the bullet line
