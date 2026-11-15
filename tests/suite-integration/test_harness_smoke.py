"""The harness itself: checkouts are mounted and dora-api answers in-process."""

import re
import socket
from pathlib import Path

import conftest
import pytest


@pytest.mark.parametrize(
    "repo",
    ["fawkes", "uFawkesObs", "uFawkesPipe", "uFawkesDevX", "uFawkesDojo", "uFawkesAI"],
)
def test_checkout_is_mounted(repo):
    assert (conftest.SUITE_ROOT / repo / "scripts" / "emit-dora-event.sh").is_file()


def test_container_has_no_network():
    with pytest.raises(OSError):
        socket.create_connection(("1.1.1.1", 53), timeout=1)


def test_dora_api_starts_empty(obs):
    assert obs.get("/health").json() == {"status": "ok", "queue_depth": 0}
    assert obs.metrics() == {}


def test_every_finding_mark_has_a_report_entry_and_every_entry_a_test() -> None:
    here = Path(__file__).parent
    marks = {
        m
        for f in here.glob("test_*.py")
        for m in re.findall(r'mark\.finding\("(AF-\d+)"\)', f.read_text())
    }
    entries = set(
        re.findall(
            r"^### (AF-\d+) ", (here / "AUDIT_FINDINGS.md").read_text(), re.MULTILINE
        )
    )

    assert marks == entries
