"""The brown belt DORA lab grader, graded. See test_dojo_grading.py."""

import re
from collections.abc import Callable
from pathlib import Path
from typing import Any

import pytest
from harness import events
from harness.graders import (
    ANSI,
    BROWN,
    BROWN_RUNNING,
    BROWN_SERVICES,
    CREDS,
    DORA_OK,
    GRAFANA,
    JSON,
    QUERY_EMPTY,
    QUERY_OK,
    TEXT,
    Graded,
    env_file,
    grade,
    grafana,
    prom,
)

# ── Brown Belt module 14 lab 01 ──────────────────────────────────────────────

BROWN_SERVICES_UP = ["dora", "grafana", "prom"]
BROWN_ENV = {"GRAFANA_ADMIN_USER": CREDS[0], "GRAFANA_ADMIN_PASSWORD": CREDS[1]}
STACK_FAIL = "uFawkesObs Stack: One or more services not healthy"


def brown(tmp_path: Path, **kw: Any) -> Graded:
    kw.setdefault("running", BROWN_RUNNING)
    kw["env"] = {**BROWN_ENV, **kw.get("env", {})}
    return grade(tmp_path, BROWN, BROWN_SERVICES_UP, **kw)


def test_brown_happy(tmp_path: Path) -> None:
    g = brown(tmp_path, health={"prometheus": "healthy", GRAFANA: "healthy"})
    assert (g.rc, g.counts) == (0, (9, 9, 0)), g.out
    assert (
        g.queued == 2
    )  # the ingestion check and the end-to-end check each POSTed one, both accepted
    prom_seen = g.servers["prom"].requests
    assert any("dora_deployment_frequency%7Bcommit_sha" in r.path for r in prom_seen)


@pytest.mark.parametrize(
    "creds_via",
    [
        pytest.param(
            lambda tp: {
                "cwd_env": env_file(),
                "env": {"GRAFANA_ADMIN_PASSWORD": "", "GRAFANA_ADMIN_USER": ""},
            },
            id="dotenv-in-cwd",
        ),
        pytest.param(
            lambda tp: {
                "env": {
                    "GRAFANA_ADMIN_PASSWORD": "",
                    "GRAFANA_ADMIN_USER": "",
                    "UF_OBS_DIR": str(tp / "obs"),
                }
            },
            id="uf-obs-dir",
        ),
    ],
)
def test_brown_happy_credentials_from_env_files(
    tmp_path: Path, creds_via: Callable[[Path], dict[str, Any]]
) -> None:
    (tmp_path / "obs").mkdir()
    (tmp_path / "obs/.env").write_text(env_file())
    g = brown(tmp_path, **creds_via(tmp_path))
    assert (g.rc, g.counts) == (0, (9, 9, 0)), g.out


@pytest.mark.parametrize(
    "container,label", BROWN_SERVICES, ids=[c for c, _ in BROWN_SERVICES]
)
def test_brown_container_not_running(
    tmp_path: Path, container: str, label: str
) -> None:
    g = brown(tmp_path, running=BROWN_RUNNING - {container})
    assert g.rc == 1 and g.failed_with(
        f"{label} ({container}): not running", STACK_FAIL
    ), g.out
    assert g.counts == (9, 8, 1), g.out


@pytest.mark.parametrize("state", ["unhealthy", "starting"])
def test_brown_container_unhealthy(tmp_path: Path, state: str) -> None:
    g = brown(tmp_path, health={"loki": state})
    assert g.rc == 1 and g.failed_with(f"Loki (loki): health={state}", STACK_FAIL), (
        g.out
    )


BROWN_SAD = [
    (
        "dora-health-500",
        {"dora": {**DORA_OK, ("GET", "/health"): (500, "", TEXT)}},
        ["DORA API: DORA API returned HTTP 500"],
    ),
    (
        "dora-down",
        {"dora": None},
        [
            "DORA API: DORA API returned HTTP 000",
            "DORA Event Ingestion: Event rejected (HTTP 000",
            "Event Ingestion → Metrics: Event submission failed (HTTP 000",
        ],
    ),
    (
        "event-rejected-422",
        {"dora": {**DORA_OK, ("POST", "/event"): (422, {"detail": "bad"}, JSON)}},
        [
            "DORA Event Ingestion: Event rejected (HTTP 422)",
            "Event Ingestion → Metrics: Event submission failed (HTTP 422)",
        ],
    ),
    (
        "prom-query-500",
        {"prom": prom(query=(500, "", TEXT))},
        [
            "DORA Metrics Query: One or more DORA metrics not queryable",
            "DORA PromQL Queries: One or more",
            "Event Ingestion → Metrics: Event accepted but not yet visible",
        ],
    ),
    (
        "prom-query-status-error",
        {"prom": prom(query=(200, {"status": "error"}, JSON))},
        ["DORA Metrics Query: One or more DORA metrics not queryable"],
    ),
    (
        "promql-histogram-400",
        {
            "prom": prom(
                query=lambda r: (
                    (400, "", TEXT) if "histogram_quantile" in r.path else QUERY_OK
                )
            )
        },
        ["DORA PromQL Queries: One or more"],
    ),
    (
        "event-metric-query-503",
        {
            "prom": prom(
                query=lambda r: (503, "", TEXT) if "commit_sha" in r.path else QUERY_OK
            )
        },
        ["Event Ingestion → Metrics: Event accepted but not yet visible"],
    ),
    (
        "rules-500",
        {"prom": prom(rules=(500, "", TEXT))},
        ["DORA Alert Rules: Could not fetch rules from Prometheus (HTTP 500)"],
    ),
    (
        "no-dora-rule-group",
        {
            "prom": prom(
                rules=(
                    200,
                    {"data": {"groups": [{"name": "node", "rules": [{}]}]}},
                    JSON,
                )
            )
        },
        ["DORA Alert Rules: No DORA alert rules found"],
    ),
    (
        "dora-group-without-rules",
        {
            "prom": prom(
                rules=(200, {"data": {"groups": [{"name": "dora", "rules": []}]}}, JSON)
            )
        },
        ["DORA Alert Rules: No DORA alert rules found"],
    ),
    (
        "no-rule-groups-at-all",
        {"prom": prom(rules=(200, {"data": {"groups": []}}, JSON))},
        ["DORA Alert Rules: No DORA alert rules found"],
    ),
    (
        "prom-down",
        {"prom": None},
        [
            "DORA Metrics Query",
            "DORA Alert Rules: Could not fetch rules from Prometheus (HTTP 000",
            "DORA PromQL Queries",
        ],
    ),
    (
        "grafana-401",
        {"env": {"GRAFANA_ADMIN_PASSWORD": "wrong"}},
        ["Grafana DORA Dashboard: Grafana API returned HTTP 401"],
    ),
    (
        "grafana-search-500",
        {"grafana": lambda r: (500, "", TEXT)},
        ["Grafana DORA Dashboard: Grafana API returned HTTP 500"],
    ),
    (
        "no-dora-dashboards",
        {"grafana": grafana(found=0)},
        ["Grafana DORA Dashboard: No DORA dashboards found"],
    ),
    (
        "grafana-down",
        {"grafana": None},
        ["Grafana DORA Dashboard: Grafana API returned HTTP 000"],
    ),
]


@pytest.mark.parametrize(
    "kw,needles", [pytest.param(k, n, id=i) for i, k, n in BROWN_SAD]
)
def test_brown_sad(tmp_path: Path, kw: dict[str, Any], needles: list[str]) -> None:
    g = brown(tmp_path, **kw)
    assert g.rc == 1 and g.failed_with(*needles), g.out
    assert g.counts[2] >= len(needles)


@pytest.mark.finding("AF-22")
def test_brown_reports_a_refused_connection_as_http_000(tmp_path: Path) -> None:
    g = brown(tmp_path, prom=None)
    assert "000000" not in g.out, g.fails


def test_brown_warn_is_counted_as_a_failure(tmp_path: Path) -> None:
    """The WARN status falls into record_test's else branch: printed as a red failure, counted failed."""
    g = brown(
        tmp_path,
        prom=prom(
            query=lambda r: (503, "", TEXT) if "commit_sha" in r.path else QUERY_OK
        ),
    )
    assert g.counts == (9, 8, 1) and g.rc == 1, g.out


@pytest.mark.finding("AF-19")
def test_brown_empty_prometheus_result_must_not_pass(tmp_path: Path) -> None:
    g = brown(tmp_path, prom=prom(query=QUERY_EMPTY))
    assert g.failed_with("DORA Metrics Query", "Event Ingestion → Metrics"), g.out
    assert g.rc == 1


@pytest.mark.finding("AF-17")
def test_brown_no_credentials_must_not_pass(tmp_path: Path) -> None:
    g = brown(tmp_path, env={"GRAFANA_ADMIN_PASSWORD": ""}, grafana=grafana(found=0))
    assert g.rc == 1, g.out


@pytest.mark.finding("AF-20")
def test_brown_default_uf_obs_dir_is_read(tmp_path: Path) -> None:
    home = tmp_path / "home"
    (home / "dojo-labs/uFawkesObs").mkdir(parents=True)
    (home / "dojo-labs/uFawkesObs/.env").write_text(env_file())
    g = brown(
        tmp_path,
        env={"GRAFANA_ADMIN_PASSWORD": "", "GRAFANA_ADMIN_USER": "", "HOME": str(home)},
    )
    assert g.failed_with() and "Grafana DORA Dashboard: Found" in ANSI.sub("", g.out), (
        g.out
    )


# The metric names the brown-belt grader queries, read from its own `metrics=( ... )` array.
GRADER_METRICS = (
    re.search(r"local metrics=\(([^)]*)\)", BROWN.read_text())
    .group(1)
    .replace('"', "")
    .split()
)


@pytest.fixture
def exported(obs: Any, now: Any) -> set[str]:
    from datetime import timedelta

    from compute.metrics import render_prometheus_text

    obs.deliver(events.deployment(1, now - timedelta(days=3)))
    text = render_prometheus_text(list(obs.metrics().values()))
    return set(re.findall(r"^# TYPE (\S+) ", text, re.MULTILINE))


def test_dora_api_exports_gauges_after_one_event(exported: set[str]) -> None:
    assert (
        "dora_deployment_frequency_per_week" in exported and "dora_cfr_pct" in exported
    )


@pytest.mark.finding("AF-19")
@pytest.mark.parametrize("metric", GRADER_METRICS)
def test_brown_metric_name_is_exported_by_dora_api(
    exported: set[str], metric: str
) -> None:
    assert metric in exported, sorted(exported)
