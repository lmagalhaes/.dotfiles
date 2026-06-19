"""Unit tests for parse_findings.py."""
import json
import subprocess
import sys
from pathlib import Path

import pytest

SKILL_DIR = Path(__file__).parent.parent
SCRIPT = SKILL_DIR / 'references' / 'parse_findings.py'
SAMPLES_DIR = SKILL_DIR / 'references' / 'samples'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def run_parser(text: str) -> tuple[int, dict | None, dict | None]:
    """Run parse_findings.py with `text` on stdin.

    Returns (exit_code, stdout_json, stderr_json).
    stdout_json / stderr_json are None when the respective stream is empty or
    not valid JSON.
    """
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        input=text,
        capture_output=True,
        text=True,
    )
    stdout = json.loads(result.stdout) if result.stdout.strip() else None
    stderr = json.loads(result.stderr) if result.stderr.strip() else None
    return result.returncode, stdout, stderr


def sample(name: str) -> str:
    return (SAMPLES_DIR / name).read_text()


# ---------------------------------------------------------------------------
# Golden sample tests
# ---------------------------------------------------------------------------

class TestFindingsSample:
    def setup_method(self):
        self.rc, self.out, self.err = run_parser(sample('findings.txt'))

    def test_exits_zero(self):
        assert self.rc == 0

    def test_status_is_findings(self):
        assert self.out['status'] == 'findings'

    def test_no_base_branch_fallback(self):
        assert self.out['base_branch_fallback'] is False

    def test_two_findings(self):
        assert len(self.out['findings']) == 2

    def test_first_finding_priority(self):
        assert self.out['findings'][0]['priority'] == 'P1'

    def test_first_finding_title(self):
        assert self.out['findings'][0]['title'] == 'Avoid reading `value` for inactive items'

    def test_first_finding_lines(self):
        f = self.out['findings'][0]
        assert f['line_start'] == 8
        assert f['line_end'] == 9

    def test_first_finding_filepath(self):
        assert self.out['findings'][0]['filepath'].endswith('sample_issues.py')

    def test_second_finding_priority(self):
        assert self.out['findings'][1]['priority'] == 'P2'

    def test_second_finding_single_line(self):
        f = self.out['findings'][1]
        assert f['line_start'] == 21
        assert f['line_end'] == 21

    def test_description_not_empty(self):
        assert self.out['findings'][0]['description'] != ''

    def test_duplicate_not_included(self):
        # The duplicate summary paragraph must not appear in any description.
        for f in self.out['findings']:
            assert 'Full review comments:' not in f['description']


class TestCleanSample:
    def setup_method(self):
        self.rc, self.out, self.err = run_parser(sample('clean.txt'))

    def test_exits_zero(self):
        assert self.rc == 0

    def test_status_is_clean(self):
        assert self.out['status'] == 'clean'

    def test_no_base_branch_fallback(self):
        assert self.out['base_branch_fallback'] is False

    def test_no_findings(self):
        assert self.out['findings'] == []


class TestFallbackSample:
    def setup_method(self):
        self.rc, self.out, self.err = run_parser(sample('failure.txt'))

    def test_exits_zero(self):
        assert self.rc == 0

    def test_status_is_findings(self):
        assert self.out['status'] == 'findings'

    def test_base_branch_fallback_detected(self):
        assert self.out['base_branch_fallback'] is True

    def test_three_findings(self):
        assert len(self.out['findings']) == 3

    def test_priorities_in_order(self):
        priorities = [f['priority'] for f in self.out['findings']]
        assert priorities == ['P1', 'P2', 'P3']

    def test_relative_filepaths(self):
        for f in self.out['findings']:
            assert f['filepath'] == 'sample_issues.py'

    def test_p3_finding_lines(self):
        p3 = self.out['findings'][2]
        assert p3['line_start'] == 17
        assert p3['line_end'] == 18


# ---------------------------------------------------------------------------
# Synthetic input tests
# ---------------------------------------------------------------------------

class TestErrorCases:
    def test_empty_input_is_error(self):
        rc, out, _ = run_parser('')
        assert rc == 0
        assert out['status'] == 'error'

    def test_no_codex_block_is_error(self):
        rc, out, _ = run_parser('OpenAI Codex v0.140.0\n--------\nworkdir: /tmp\n')
        assert rc == 0
        assert out['status'] == 'error'

    def test_error_has_no_findings(self):
        _, out, _ = run_parser('')
        assert out['findings'] == []

    def test_error_base_branch_fallback_false(self):
        _, out, _ = run_parser('')
        assert out['base_branch_fallback'] is False


class TestParseError:
    def test_full_review_section_with_no_bullets_exits_one(self):
        text = 'codex\nSome summary.\n\nFull review comments:\n\n'
        rc, _, err = run_parser(text)
        assert rc == 1

    def test_parse_error_has_status_field(self):
        text = 'codex\nSome summary.\n\nFull review comments:\n\n'
        _, _, err = run_parser(text)
        assert err['status'] == 'parse_error'

    def test_parse_error_has_reason_field(self):
        text = 'codex\nSome summary.\n\nFull review comments:\n\n'
        _, _, err = run_parser(text)
        assert 'reason' in err


class TestCleanVariants:
    def test_no_full_review_section_is_clean(self):
        text = 'codex\nno changes in this worktree.\nno changes in this worktree.\n'
        rc, out, _ = run_parser(text)
        assert rc == 0
        assert out['status'] == 'clean'

    def test_clean_has_no_findings(self):
        text = 'codex\nno changes in this worktree.\nno changes in this worktree.\n'
        _, out, _ = run_parser(text)
        assert out['findings'] == []


class TestFallbackDetection:
    def test_no_fallback_when_signal_absent(self):
        text = (
            'codex\n'
            'Reviewed against origin/main as requested.\n\n'
            'Full review comments:\n\n'
            '- [P1] A bug — src/foo.py:1-1\n'
            '  description\n'
        )
        _, out, _ = run_parser(text)
        assert out['base_branch_fallback'] is False

    def test_fallback_detected_with_origin_ref(self):
        # Codex quotes the fallback ref in backticks.
        text = (
            'codex\n'
            'The branch could not be resolved, so I reviewed against `origin/main`.\n\n'
            'Full review comments:\n\n'
            '- [P1] A bug — src/foo.py:1-1\n'
            '  description\n'
        )
        _, out, _ = run_parser(text)
        assert out['base_branch_fallback'] is True

    def test_fallback_detected_with_upstream_ref(self):
        # Any backtick-quoted remote ref triggers fallback, not just origin/.
        text = (
            'codex\n'
            'The branch could not be resolved, so I reviewed against `upstream/main`.\n\n'
            'Full review comments:\n\n'
            '- [P1] A bug — src/foo.py:1-1\n'
            '  description\n'
        )
        _, out, _ = run_parser(text)
        assert out['base_branch_fallback'] is True

    def test_no_fallback_without_ref(self):
        # "could not be resolved" alone is not enough — no ref means no fallback flag.
        text = (
            'codex\n'
            'The requested base branch could not be resolved.\n\n'
            'Full review comments:\n\n'
            '- [P1] A bug — src/foo.py:1-1\n'
            '  description\n'
        )
        _, out, _ = run_parser(text)
        assert out['base_branch_fallback'] is False


class TestFindingParsing:
    def _single_finding(self, header_line: str, description: str = '  desc') -> dict:
        text = (
            'codex\nSummary.\n\n'
            'Full review comments:\n\n'
            f'{header_line}\n{description}\n'
        )
        _, out, _ = run_parser(text)
        return out['findings'][0]

    def test_absolute_filepath(self):
        f = self._single_finding('- [P1] Title — /abs/path/file.py:5-10')
        assert f['filepath'] == '/abs/path/file.py'

    def test_relative_filepath(self):
        f = self._single_finding('- [P2] Title — relative/file.py:3-3')
        assert f['filepath'] == 'relative/file.py'

    def test_single_line_range(self):
        f = self._single_finding('- [P1] Title — file.py:42-42')
        assert f['line_start'] == 42
        assert f['line_end'] == 42

    def test_multi_line_range(self):
        f = self._single_finding('- [P3] Title — file.py:10-20')
        assert f['line_start'] == 10
        assert f['line_end'] == 20

    def test_description_stripped(self):
        f = self._single_finding('- [P1] Title — file.py:1-1', '  leading spaces stripped  ')
        assert f['description'] == 'leading spaces stripped'

    def test_duplicate_truncation_stops_at_summary(self):
        text = (
            'codex\nSummary text.\n\n'
            'Full review comments:\n\n'
            '- [P1] First — file.py:1-1\n'
            '  desc\n'
            '\n'
            'Summary text.\n'  # duplicate summary starts here
            '\n'
            'Full review comments:\n\n'
            '- [P1] First — file.py:1-1\n'
            '  desc\n'
        )
        _, out, _ = run_parser(text)
        assert len(out['findings']) == 1

    def test_uses_last_codex_block_not_first(self):
        # Exec output earlier in the transcript can contain bare "codex" lines
        # (e.g., when codex reads SKILL.md). Parser must use the LAST occurrence.
        text = (
            'exec\n'
            '/bin/bash -lc cat SKILL.md\n'
            ' succeeded in 100ms:\n'
            'codex\n'                         # fake — inside exec output
            'Some old summary.\n\n'
            'Full review comments:\n\n'
            '- [P1] Fake finding — fake.py:1-1\n'
            '  should not appear\n'
            '\n'
            'codex\n'                         # real — last occurrence
            'Real summary.\n\n'
            'Full review comments:\n\n'
            '- [P2] Real finding — real.py:5-5\n'
            '  real description\n'
        )
        _, out, _ = run_parser(text)
        assert len(out['findings']) == 1
        assert out['findings'][0]['title'] == 'Real finding'
        assert out['findings'][0]['filepath'] == 'real.py'

    def test_title_with_em_dash_splits_at_last_separator(self):
        # Title contains an em-dash — parser must split at the LAST one.
        f = self._single_finding('- [P1] Handle nil — empty input — src/foo.py:1-1')
        assert f['title'] == 'Handle nil — empty input'
        assert f['filepath'] == 'src/foo.py'

    def test_noise_before_codex_marker_ignored(self):
        text = (
            '# comment\n'
            'OpenAI Codex v0.140.0\n'
            '--------\n'
            'workdir: /tmp\n'
            '--------\n'
            'user\n'
            'changes against main\n'
            'exec\n'
            '/bin/bash -lc git diff\n'
            '\n'
            'codex\n'
            'Summary.\n\n'
            'Full review comments:\n\n'
            '- [P2] A finding — src/main.py:7-8\n'
            '  explanation\n'
        )
        _, out, _ = run_parser(text)
        assert out['status'] == 'findings'
        assert len(out['findings']) == 1


class TestSingularReviewCommentForm:
    """gpt-5.4 sometimes emits 'Review comment:' (singular) instead of
    'Full review comments:' — the parser must treat both as the section header."""

    def _text_with_singular_header(self) -> str:
        return (
            'codex\n'
            'Summary.\n\n'
            'Review comment:\n\n'
            '- [P1] A bug — src/foo.py:3-5\n'
            '  explanation\n'
        )

    def test_singular_header_yields_findings_status(self):
        _, out, _ = run_parser(self._text_with_singular_header())
        assert out['status'] == 'findings'

    def test_singular_header_parses_finding(self):
        _, out, _ = run_parser(self._text_with_singular_header())
        assert len(out['findings']) == 1

    def test_singular_header_finding_priority(self):
        _, out, _ = run_parser(self._text_with_singular_header())
        assert out['findings'][0]['priority'] == 'P1'

    def test_singular_header_finding_filepath(self):
        _, out, _ = run_parser(self._text_with_singular_header())
        assert out['findings'][0]['filepath'] == 'src/foo.py'

    def test_singular_header_duplicate_backstop(self):
        text = (
            'codex\n'
            'Summary.\n\n'
            'Review comment:\n\n'
            '- [P1] First — file.py:1-1\n'
            '  desc\n'
            '\n'
            'Summary.\n'
            '\n'
            'Review comment:\n\n'
            '- [P1] First — file.py:1-1\n'
            '  desc\n'
        )
        _, out, _ = run_parser(text)
        assert len(out['findings']) == 1
