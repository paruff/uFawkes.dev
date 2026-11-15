"""Shared fixtures for the suite integration harness. See run.sh."""

import os
import random
import sys
from datetime import UTC, datetime
from pathlib import Path

import pytest

SUITE_ROOT = Path(os.environ.get("SUITE_ROOT", "/suite"))
OBS = SUITE_ROOT / "uFawkesObs"
PIPE = SUITE_ROOT / "uFawkesPipe"
DEVX = SUITE_ROOT / "uFawkesDevX"
DOJO = SUITE_ROOT / "uFawkesDojo"
FAWKES = SUITE_ROOT / "fawkes"
AI = SUITE_ROOT / "uFawkesAI"
SITE = SUITE_ROOT / "uFawkes.dev"
FIXTURES = Path(__file__).parent / "fixtures"

# dora-api's own import layout (its Dockerfile copies dora/ to /app).
sys.path.insert(0, str(OBS / "dora"))

from harness.obs import ObsStack


def pytest_collection_modifyitems(items: list[pytest.Item]) -> None:
    # A different order per run (run.sh sets SUITE_SEED): a test that only
    # passes after another one fails here instead of in CI months later.
    seed = os.environ.get("SUITE_SEED")
    if seed:
        random.Random(seed).shuffle(items)


_reproduced: list[str] = []


@pytest.hookimpl(wrapper=True)
def pytest_pyfunc_call(pyfuncitem: pytest.Function):
    """A test marked finding("AF-nn") is the reproduction of a known bug.

    Its body asserts the correct behaviour. While the bug is there the body
    fails, and that is the pass: the bug reproduces. When the body passes, the
    test fails, so the fix, the mark and the report entry go together.
    Only the test body is covered: a broken fixture is still an error.
    """
    mark = pyfuncitem.get_closest_marker("finding")
    if mark is None or os.environ.get("SUITE_ASSERT_FIXED"):
        return (yield)
    try:
        yield
    # A bug shows as a wrong result, or as the error the mark names with
    # raises=. Anything else is a harness fault and fails the test.
    except mark.kwargs.get("raises", AssertionError):
        _reproduced.append(mark.args[0])
        return True
    pytest.fail(
        f"{mark.args[0]} no longer reproduces: remove the finding mark and its AUDIT_FINDINGS.md entry",
        pytrace=False,
    )


def pytest_terminal_summary(terminalreporter: pytest.TerminalReporter) -> None:
    if _reproduced:
        terminalreporter.write_line(
            f"{len(_reproduced)} of the passing tests reproduce {len(set(_reproduced))} known findings (AUDIT_FINDINGS.md)"
        )


@pytest.fixture
def obs(tmp_path, monkeypatch):
    """A fresh dora-api on an empty database, with auth off."""
    monkeypatch.delenv("DORA_API_KEY", raising=False)
    monkeypatch.setenv("DATABASE_URL", "")  # restored on teardown; ObsStack sets it
    stack = ObsStack(tmp_path / "dora.db")
    yield stack
    stack.close()


@pytest.fixture
def now():
    """One reading of the clock per test. Tests place events days away from
    any window edge, so the exact value never changes an outcome."""
    return datetime.now(UTC).replace(microsecond=0)
