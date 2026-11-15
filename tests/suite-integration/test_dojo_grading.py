"""How the uFawkesDojo DORA lab graders grade, offline.

Each grader runs as the learner would run it, against the real dora-api on
:8088 plus stub servers on the ports it hardcodes, and a stub `docker`/`sleep`
on PATH. A correct grader fails a learner who has not done the lab and passes
one who has. Where a grader does not, the test carries a `finding` mark
naming its entry in AUDIT_FINDINGS.md.
"""

import json
import subprocess
from pathlib import Path
from typing import Any

import conftest
import pytest
from harness import events
from harness.graders import (
    ANSI,
    CREDS,
    DORA,
    DORA_OK,
    GRAFANA,
    JSON,
    LAB1,
    LAB2,
    LAB_RUNNING,
    METRICS,
    OVERVIEW,
    QUERY_EMPTY,
    TEXT,
    Graded,
    env_file,
    grade,
    grafana,
)

# ── White Belt lab 01 ────────────────────────────────────────────────────────

LAB1_SERVICES = ["dora", "grafana"]
# What dora-api serves once the learner's events have been computed.
DORA_AFTER_THE_LAB = {
    **DORA_OK,
    ("GET", "/metrics"): (
        200,
        'dora_deployment_frequency_per_week{team_id="dojo-lab/test",tier="high"} 1.0\n',
        TEXT,
    ),
}


def lab1(tmp_path: Path, **kw: Any) -> Graded:
    kw.setdefault("running", LAB_RUNNING)
    kw.setdefault("cwd_env", env_file())
    kw.setdefault("dora", DORA_AFTER_THE_LAB)
    return grade(tmp_path, LAB1, LAB1_SERVICES, **kw)


def test_lab1_happy(tmp_path: Path) -> None:
    g = lab1(tmp_path)
    assert (g.rc, g.counts) == (0, (8, 8, 0)), g.out


LAB1_SAD = [
    ("no-docker", {"running": None}, ["Prerequisites: docker and/or curl not found"]),
    (
        "dora-container",
        {"running": {GRAFANA}},
        ["dora-api container (ufawkesdora-ingestion) is not running"],
    ),
    (
        "grafana-container",
        {"running": {DORA}},
        ["grafana container (grafana) is not running"],
    ),
    (
        "metrics-500",
        {
            "dora": {
                ("GET", "/health"): DORA_OK[("GET", "/health")],
                ("GET", "/metrics"): (500, "", TEXT),
            }
        },
        ["DORA Compute: dora-api /metrics returned HTTP 500"],
    ),
    (
        "health-500",
        {
            "dora": {
                ("GET", "/health"): (500, "", TEXT),
                ("GET", "/metrics"): (200, "", TEXT),
            }
        },
        ["dora-api Health: dora-api returned HTTP 500"],
    ),
    (
        "health-no-queue-depth",
        {
            "dora": {
                ("GET", "/health"): (200, {"status": "ok"}, JSON),
                ("GET", "/metrics"): (200, "", TEXT),
            }
        },
        ["dora-api Health"],
    ),
    (
        "dora-down",
        {"dora": None},
        [
            "dora-api Health: dora-api returned HTTP 000",
            "DORA Compute: dora-api /metrics returned HTTP 000",
        ],
    ),
    ("grafana-down", {"grafana": None}, ["Grafana Health: Grafana returned HTTP 000"]),
    (
        "grafana-401",
        {"cwd_env": env_file(("admin", "wrong"))},
        [
            "DORA Overview Dashboard: Grafana API returned HTTP 401",
            "DORA Metrics Dashboard: Grafana API returned HTTP 401",
        ],
    ),
    (
        "overview-404",
        {"grafana": grafana(uids=(METRICS,))},
        ["DORA Overview Dashboard: Grafana API returned HTTP 404"],
    ),
    (
        "metrics-404",
        {"grafana": grafana(uids=(OVERVIEW,))},
        ["DORA Metrics Dashboard: Grafana API returned HTTP 404"],
    ),
]


@pytest.mark.parametrize(
    "kw,needles", [pytest.param(k, n, id=i) for i, k, n in LAB1_SAD]
)
def test_lab1_sad(tmp_path: Path, kw: dict[str, Any], needles: list[str]) -> None:
    g = lab1(tmp_path, **kw)
    assert g.rc == 1 and g.failed_with(*needles), g.out
    assert g.counts[2] >= len(needles)


@pytest.mark.finding("AF-16")
def test_lab1_zero_events_must_not_pass(tmp_path: Path) -> None:
    g = lab1(
        tmp_path, dora=DORA_OK
    )  # healthy, and /metrics is empty: nothing was ever sent
    assert g.rc == 1, g.out


@pytest.mark.finding("AF-17")
def test_lab1_no_env_must_not_pass(tmp_path: Path) -> None:
    g = lab1(tmp_path, cwd_env=None, grafana=grafana(uids=()))
    assert "skipped" in ANSI.sub("", g.out), g.out  # the skip does happen
    assert g.rc == 1, g.out


# ── White Belt lab 02 ────────────────────────────────────────────────────────

LAB2_SERVICES = ["dora", "grafana", "otlp", "loki"]
ADMIN_ENV = {"GRAFANA_ADMIN_USER": CREDS[0], "GRAFANA_ADMIN_PASSWORD": CREDS[1]}


def lab2(tmp_path: Path, **kw: Any) -> Graded:
    kw.setdefault("running", LAB_RUNNING)
    kw["env"] = {
        "UFAWKESAI_ROOT": str(conftest.AI),
        "GITHUB_SHA": events.sha(7),
        **ADMIN_ENV,
        **kw.get("env", {}),
    }
    return grade(tmp_path, LAB2, LAB2_SERVICES, **kw)


def otlp_records(g: Graded) -> list[dict[str, Any]]:
    """The emitted events, decoded from what the OTLP stub received."""
    return [
        json.loads(
            json.loads(r.text)["resourceLogs"][0]["scopeLogs"][0]["logRecords"][0][
                "body"
            ]["stringValue"]
        )
        for r in g.servers["otlp"].requests
    ]


def test_lab2_happy(tmp_path: Path) -> None:
    g = lab2(tmp_path)
    assert (g.rc, g.counts) == (0, (16, 16, 0)), g.out
    sent = otlp_records(g)
    assert [e["event"] for e in sent] == ["deploy-marker", "job-finish"]
    deploy = sent[0]
    assert (
        deploy["repo"],
        deploy["environment"],
        deploy["status"],
        deploy["commit_sha"],
    ) == ("dojo-lab/test", "production", "success", events.sha(7))
    assert deploy["dora_event"]["event_type"] == "deployment"
    assert all(r.path == "/v1/logs" for r in g.servers["otlp"].requests)
    assert any("/loki/api/v1/query_range" in r.path for r in g.servers["loki"].requests)


@pytest.mark.finding("AF-12")
def test_lab2_emitted_event_is_accepted_by_dora_api(tmp_path: Path, obs: Any) -> None:
    """The lab teaches this emitter; the event it produces must be one dora-api takes."""
    event = otlp_records(lab2(tmp_path))[0]["dora_event"]
    reply = obs.post("/event", event)
    assert reply.status_code == 201, (event, reply.text)


def fake_ai(tmp_path: Path, emit: Path | None, verify: bool = True) -> Path:
    root = tmp_path / "ai"
    (root / "scripts").mkdir(parents=True)
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    if emit:
        (root / "scripts/emit-dora-event.sh").write_text(emit.read_text())
    if verify:
        (root / "scripts/verify-dora-event-in-loki.sh").write_text(
            (conftest.AI / "scripts/verify-dora-event-in-loki.sh").read_text()
        )
    return root


LAB2_SAD = [
    ("no-docker", {"running": None}, ["Prerequisite: docker is NOT installed"]),
    (
        "dora-container",
        {"running": {GRAFANA}},
        ["Stack: ufawkesdora-ingestion container is NOT running"],
    ),
    (
        "grafana-container",
        {"running": {DORA}},
        ["Stack: grafana container is NOT running"],
    ),
    (
        "metrics-500",
        {
            "dora": {
                ("GET", "/health"): DORA_OK[("GET", "/health")],
                ("GET", "/metrics"): (500, "", TEXT),
            }
        },
        ["dora-api DORA metrics (in-process compute): NOT reachable"],
    ),
    (
        "health-500",
        {
            "dora": {
                ("GET", "/health"): (500, "", TEXT),
                ("GET", "/metrics"): (200, "", TEXT),
            }
        },
        ["dora-api Health: NOT reachable"],
    ),
    ("grafana-down", {"grafana": None}, ["Grafana Health: NOT reachable"]),
    (
        "dashboard-401",
        {"env": {"GRAFANA_ADMIN_PASSWORD": "wrong"}},
        ["Grafana Dashboard: Grafana API returned HTTP 401"],
    ),
    (
        "dashboards-404",
        {"grafana": grafana(uids=())},
        ["Grafana Dashboard: Grafana API returned HTTP 404"],
    ),
    (
        "otlp-down-event-never-in-loki",
        {"otlp": None},
        ["verify-dora-event-in-loki.sh: marker event NOT found in Loki"],
    ),
    (
        "otlp-rejects",
        {
            "otlp": {("POST", "/v1/logs"): (500, "", TEXT)},
            "loki": {("GET", "/"): QUERY_EMPTY},
        },
        ["verify-dora-event-in-loki.sh: marker event NOT found in Loki"],
    ),
]


@pytest.mark.parametrize(
    "kw,needles", [pytest.param(k, n, id=i) for i, k, n in LAB2_SAD]
)
def test_lab2_sad(tmp_path: Path, kw: dict[str, Any], needles: list[str]) -> None:
    g = lab2(tmp_path, **kw)
    assert g.rc == 1 and g.failed_with(*needles), g.out


@pytest.mark.finding("AF-21")
def test_lab2_passes_without_the_optional_gh_cli(tmp_path: Path) -> None:
    g = lab2(tmp_path, gh=False)
    assert "PR metadata will be limited" in g.out  # the grader itself calls gh optional
    assert g.rc == 0, g.out


@pytest.mark.finding("AF-24")
def test_lab2_finds_its_containers_on_a_host_that_runs_many(tmp_path: Path) -> None:
    # Both containers are listed first, then enough others that docker is
    # still writing when `grep -q` has its match and stops reading.
    busy_host = f"echo {DORA}; echo {GRAFANA}; yes other-container | head -n 200000"
    g = lab2(tmp_path, docker_script=busy_host)
    assert g.rc == 0, g.fails


def test_lab2_dashboard_fallback_to_overview_passes(tmp_path: Path) -> None:
    g = lab2(tmp_path, grafana=grafana(uids=(OVERVIEW,)))
    assert (g.rc, g.counts) == (0, (16, 16, 0)), g.out


def test_lab2_emitter_missing(tmp_path: Path) -> None:
    g = lab2(tmp_path, env={"UFAWKESAI_ROOT": str(fake_ai(tmp_path, None))})
    assert g.rc == 1 and g.failed_with("emit-dora-event.sh NOT found"), g.out


def test_lab2_verify_script_missing(tmp_path: Path) -> None:
    g = lab2(
        tmp_path,
        env={
            "UFAWKESAI_ROOT": str(
                fake_ai(
                    tmp_path, conftest.AI / "scripts/emit-dora-event.sh", verify=False
                )
            )
        },
    )
    assert g.rc == 1 and g.failed_with("verify-dora-event-in-loki.sh NOT found"), g.out


@pytest.mark.finding("AF-12")
@pytest.mark.parametrize("repo", ["uFawkesPipe", "uFawkesDevX", "fawkes", "uFawkesObs"])
def test_lab2_works_with_every_repos_copy_of_the_emitter(
    tmp_path: Path, repo: str
) -> None:
    # The emitter is meant to be one script. The grader passes flags only uFawkesAI's copy has.
    emitter = conftest.SUITE_ROOT / repo / "scripts/emit-dora-event.sh"
    g = lab2(tmp_path, env={"UFAWKESAI_ROOT": str(fake_ai(tmp_path, emitter))})
    assert g.rc == 0, g.fails


@pytest.mark.finding("AF-17")
def test_lab2_loki_down_must_not_pass(tmp_path: Path) -> None:
    g = lab2(tmp_path, loki=None)
    assert "Loki not reachable (SKIP)" in ANSI.sub("", g.out)
    assert g.rc == 1, g.out


@pytest.mark.finding("AF-18")
def test_lab2_dotenv_in_cwd_is_read(tmp_path: Path) -> None:
    g = lab2(
        tmp_path,
        cwd_env=env_file(),
        env={"GRAFANA_ADMIN_USER": "", "GRAFANA_ADMIN_PASSWORD": ""},
    )
    assert g.rc == 0, g.out
