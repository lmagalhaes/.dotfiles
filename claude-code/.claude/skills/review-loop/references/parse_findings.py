#!/usr/bin/env python3
"""Parse `codex review` stdout into structured JSON.

Reads from stdin. On success exits 0 and prints JSON to stdout.
On ambiguous input exits 1 and prints {"status":"parse_error","reason":"..."} to stderr.
"""
import json
import re
import sys

# Finding header line: - [P1] Title — filepath:start-end
# The separator is U+2014 (em-dash), not a hyphen.
# Greedy (.+) for the title so the split happens at the LAST em-dash,
# handling titles that themselves contain em-dashes.
_FINDING_RE = re.compile(r'^- \[P(\d+)\] (.+) — (.+):(\d+)-(\d+)$')

_FALLBACK_SIGNAL_RE = re.compile(r'could not be resolved', re.IGNORECASE)
# Backtick-quoted remote ref in the codex summary, e.g. `origin/main` or `upstream/main`.
# Codex always quotes the fallback ref this way in its "could not be resolved" message.
_FALLBACK_BRANCH_RE = re.compile(r'`\S+/\S+`')

_FULL_REVIEW_COMMENTS = 'Full review comments:'


def _parse_error(reason: str) -> None:
    sys.stderr.write(json.dumps({"status": "parse_error", "reason": reason}) + '\n')
    sys.exit(1)


def parse(text: str) -> dict:
    lines = text.splitlines()

    # Locate the start of the codex response block.
    # Use the LAST occurrence — exec blocks that read skill docs can contain
    # bare "codex" lines in their output, and the real response is always last.
    codex_start = None
    for i, line in enumerate(lines):
        if line == 'codex':
            codex_start = i + 1

    if codex_start is None:
        return {"status": "error", "base_branch_fallback": False, "findings": []}

    codex_lines = lines[codex_start:]

    # Detect base-branch fallback from the summary paragraph (everything before
    # the first "Full review comments:" line).
    summary_parts = []
    for line in codex_lines:
        if line == _FULL_REVIEW_COMMENTS:
            break
        summary_parts.append(line)
    summary = '\n'.join(summary_parts)

    base_branch_fallback = bool(
        _FALLBACK_SIGNAL_RE.search(summary) and _FALLBACK_BRANCH_RE.search(summary)
    )

    # Locate the first "Full review comments:" section.
    frc_index = None
    for i, line in enumerate(codex_lines):
        if line == _FULL_REVIEW_COMMENTS:
            frc_index = i
            break

    if frc_index is None:
        return {"status": "clean", "base_branch_fallback": base_branch_fallback, "findings": []}

    # Parse finding bullets. Stop when the duplicate section begins.
    findings = []
    current = None
    desc_lines = []

    for line in codex_lines[frc_index + 1:]:
        # Second "Full review comments:" is the duplicate backstop — stop here.
        if line == _FULL_REVIEW_COMMENTS:
            break

        m = _FINDING_RE.match(line)
        if m:
            if current is not None:
                current['description'] = '\n'.join(desc_lines).strip()
                findings.append(current)
            current = {
                "priority": f"P{m.group(1)}",
                "title": m.group(2),
                "filepath": m.group(3),
                "line_start": int(m.group(4)),
                "line_end": int(m.group(5)),
                "description": "",
            }
            desc_lines = []
        elif current is not None:
            if line.startswith('  '):
                desc_lines.append(line.strip())
            elif line == '':
                pass  # blank line between findings — skip
            else:
                # Non-empty, non-indented, non-bullet line — duplicate summary begins.
                break

    if current is not None:
        current['description'] = '\n'.join(desc_lines).strip()
        findings.append(current)

    if not findings:
        _parse_error(
            "Found 'Full review comments:' section but no parseable finding bullets. "
            "Output format may have changed."
        )

    return {"status": "findings", "base_branch_fallback": base_branch_fallback, "findings": findings}


def main() -> None:
    text = sys.stdin.read()
    try:
        result = parse(text)
    except SystemExit:
        raise
    except Exception as exc:
        _parse_error(str(exc))

    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
