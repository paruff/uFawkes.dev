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
    for item in items:
        mark = item.get_closest_marker("finding")
        if mark and not os.environ.get("SUITE_NO_XFAIL"):
            # strict: the day the bug is fixed the test passes, the run fails,
            # and the mark has to come off together with the finding.
            item.add_marker(pytest.mark.xfail(strict=True, reason=mark.args[0]))
    # A different order per run (run.sh sets SUITE_SEED): a test that only
    # passes after another one fails here instead of in CI months later.
    seed = os.environ.get("SUITE_SEED")
    if seed:
        random.Random(seed).shuffle(items)


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
