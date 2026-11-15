"""How the uFawkesDojo DORA lab graders grade, offline.

Each grader runs as the learner would run it, against the real dora-api on
:8088 plus stub servers on the ports it hardcodes, and a stub `docker`/`sleep`
on PATH. A correct grader fails a learner who has not done the lab and passes
one who has. Where a grader does not, the test carries a `finding` mark
naming its entry in AUDIT_FINDINGS.md.
"""

import base64
import json
import re
import subprocess
from collections.abc import Callable, Iterator
from contextlib import ExitStack
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

import conftest
import pytest
from harness import events
from harness.stubs import (
    RealDoraApi,
    Request,
    Response,
    StubServer,
    docker_stub,
    run_grader,
    stub_bin,
)

LAB1 = conftest.DOJO / "white-belt/module-02-dora-metrics/lab-01/validate.sh"
LAB2 = conftest.DOJO / "white-belt/module-02-dora-metrics/lab-02/validate.sh"
BROWN = conftest.DOJO / "brown-belt/module-14-dora-deep-dive/lab-01/validate.sh"

JSON, TEXT = "application/json", "text/plain"
PORTS = {"dora": 8088, "grafana": 3000, "prom": 9090, "loki": 3100, "otlp": 4318}
CREDS = ("admin", "s3cret")
OVERVIEW, METRICS = "ufawkesobs-dora-overview", "ufawkesobs-dora-metrics"
DORA, GRAFANA = "ufawkesdora-ingestion", "grafana"
BROWN_SERVICES = [
    ("prometheus", "Prometheus"),
    (GRAFANA, "Grafana"),
    ("loki", "Loki"),
    ("tempo", "Tempo"),
    ("alertmanager", "Alertmanager"),
    ("alloy", "Alloy"),
    ("otel-collector", "OTel Collector"),
    ("node-exporter", "Node Exporter"),
    (DORA, "DORA API (ingestion + compute)"),
]
BROWN_RUNNING = {name for name, _ in BROWN_SERVICES}
LAB_RUNNING = {DORA, GRAFANA}
ANSI = re.compile(r"\x1b\[[0-9;]*m")

DORA_OK: dict[tuple[str, str], Response] = {
    ("GET", "/health"): (200, {"status": "ok", "queue_depth": 0}, JSON),
    ("GET", "/metrics"): (200, "", TEXT),
    ("POST", "/event"): (201, {"id": 1}, JSON),
}


_api: RealDoraApi | None = None


@pytest.fixture(scope="session", autouse=True)
def _real_dora_api(tmp_path_factory: pytest.TempPathFactory) -> Iterator[None]:
    """One real dora-api for the run, started on first use. grade() resets it, or stops it when
    a test needs :8088 down or stubbed; the next test that wants it restarts it."""
    global _api
    _api = RealDoraApi(tmp_path_factory.mktemp("dora-api"))
    yield
    _api.stop()
    _api = None


def _auth_ok(req: Request, creds: tuple[str, str]) -> bool:
    got = {k.lower(): v for k, v in req.headers.items()}.get("authorization")
    return got == "Basic " + base64.b64encode(":".join(creds).encode()).decode()


def grafana(
    creds: tuple[str, str] = CREDS,
    uids: tuple[str, ...] = (OVERVIEW, METRICS),
    found: int = 2,
    search: int = 200,
) -> Callable[[Request], Response]:
    def handle(req: Request) -> Response:
        if req.path.startswith("/api/health"):
            return 200, {"database": "ok"}, JSON
        if not _auth_ok(req, creds):
            return 401, {"message": "Invalid username or password"}, JSON
        if req.path.startswith("/api/dashboards/uid/"):
            return (
                (200, {"dashboard": {}}, JSON)
                if req.path.rsplit("/", 1)[1] in uids
                else (404, {"message": "not found"}, JSON)
            )
        if req.path.startswith("/api/search"):
            return search, [{"title": "DORA"}] * found, JSON
        return 404, "", TEXT

    return handle


QUERY_OK: Response = (
    200,
    {
        "status": "success",
        "data": {"resultType": "vector", "result": [{"metric": {}, "value": [0, "1"]}]},
    },
    JSON,
)
QUERY_EMPTY: Response = (
    200,
    {"status": "success", "data": {"resultType": "vector", "result": []}},
    JSON,
)
RULES_OK: Response = (
    200,
    {
        "status": "success",
        "data": {
            "groups": [{"name": "dora-alerts", "rules": [{"name": "a"}, {"name": "b"}]}]
        },
    },
    JSON,
)


def prom(
    query: Response | Callable[[Request], Response] = QUERY_OK,
    rules: Response = RULES_OK,
) -> Callable[[Request], Response]:
    def handle(req: Request) -> Response:
        if req.path.startswith("/api/v1/rules"):
            return rules
        if req.path.startswith("/api/v1/query"):
            return query(req) if callable(query) else query
        return 404, "", TEXT

    return handle


def loki(servers: dict[str, Any]) -> Callable[[Request], Response]:
    """Answers query_range with the OTLP log record whose body holds the queried marker."""

    def handle(req: Request) -> Response:
        if req.path.startswith("/ready"):
            return 200, "ready", TEXT
        marker = re.search(
            r'step="([^"]+)"', parse_qs(urlparse(req.path).query)["query"][0]
        )
        values = []
        for sent in servers["otlp"].requests if "otlp" in servers else []:
            record = json.loads(sent.text)["resourceLogs"][0]["scopeLogs"][0][
                "logRecords"
            ][0]
            if marker and marker.group(1) in record["body"]["stringValue"]:
                values.append(["1", record["body"]["stringValue"]])
        return (
            200,
            {
                "status": "success",
                "data": {"result": [{"values": values}] if values else []},
            },
            JSON,
        )

    return handle


@dataclass
class Graded:
    rc: int
    out: str
    servers: dict[str, Any]
    queued: int  # rows in the real dora-api's event_queue when the grader finished

    def _count(self, label: str) -> int:
        return int(re.search(rf"{label}\s*:\s*(\d+)", self.out).group(1))

    @property
    def counts(self) -> tuple[int, int, int]:
        return self._count("Total Tests"), self._count("Passed"), self._count("Failed")

    @property
    def fails(self) -> list[str]:
        return [ANSI.sub("", ln) for ln in self.out.splitlines() if "✗" in ln]

    def failed_with(self, *needles: str) -> bool:
        return all(any(n in ln for ln in self.fails) for n in needles)


def grade(
    tmp_path: Path,
    script: Path,
    wanted: list[str],
    *,
    running: set[str] | None,
    health: dict[str, str] | None = None,
    env: dict[str, str] | None = None,
    cwd_env: str | None = None,
    gh: bool = True,
    docker_script: str | None = None,
    creds: tuple[str, str] = CREDS,
    **over: Any,
) -> Graded:
    """over[name] = None leaves that service down; a routes dict or callable replaces its stub."""
    cwd, bin_dir = tmp_path / "cwd", tmp_path / "bin"
    cwd.mkdir()
    if cwd_env is not None:
        (cwd / ".env").write_text(cwd_env)
    if docker_script is not None:
        stub_bin(bin_dir, "docker", docker_script)
    elif running is not None:
        docker_stub(bin_dir, running, health)
    stub_bin(bin_dir, "sleep", "exit 0")
    if gh:
        stub_bin(
            bin_dir, "gh", "exit 1"
        )  # installed, not logged in: the emitter omits PR metadata
    with ExitStack() as stack:
        servers: dict[str, Any] = {}
        for name in wanted:
            spec = over.get(name, "default")
            if spec is None and name != "dora":
                continue
            if name == "dora":
                assert _api is not None
                if spec == "default":
                    _api.start()
                    _api.reset()
                    servers[name] = _api
                    continue
                _api.stop()
                if spec is None:
                    continue
            defaults = {
                "dora": DORA_OK,
                "grafana": grafana(creds),
                "prom": prom(),
                "otlp": {("POST", "/v1/logs"): (200, "{}", JSON)},
                "loki": loki(servers),
            }
            servers[name] = stack.enter_context(
                StubServer(PORTS[name], defaults[name] if spec == "default" else spec)
            )
        rc, out = run_grader(
            script, {"VERIFY_TIMEOUT_SECONDS": "1", **(env or {})}, cwd, bin_dir
        )
        queued = _api.queued_events() if servers.get("dora") is _api else 0
    return Graded(rc, out, servers, queued)


def env_file(creds: tuple[str, str] = CREDS) -> str:
    return f"GRAFANA_ADMIN_USER={creds[0]}\nGRAFANA_ADMIN_PASSWORD={creds[1]}\n"


# ── White Belt lab 01 ────────────────────────────────────────────────────────

LAB1_SERVICES = ["dora", "grafana"]


def lab1(tmp_path: Path, **kw: Any) -> Graded:
    kw.setdefault("running", LAB_RUNNING)
    kw.setdefault("cwd_env", env_file())
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
    g = lab1(tmp_path)
    assert g.queued == 0
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
    assert (
        deploy["dora_event"]["deployment_intent"] == "planned"
        and deploy["dora_event"]["event_type"] == "deployment"
    )
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
    # Both containers are listed first; docker then keeps writing, as it does
    # on a host with enough containers to need a second write.
    busy_host = f"echo {DORA}; echo {GRAFANA}; while echo other-container; do :; done"
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


@pytest.mark.parametrize("repo", ["uFawkesPipe", "uFawkesDevX", "fawkes", "uFawkesObs"])
def test_lab2_other_emitter_copies_reject_the_graders_flags(
    tmp_path: Path, repo: str
) -> None:
    """Suspicion (e): only uFawkesAI's copy accepts --deployment-intent/--repo; the grader fails the others."""
    g = lab2(
        tmp_path,
        env={
            "UFAWKESAI_ROOT": str(
                fake_ai(
                    tmp_path, conftest.SUITE_ROOT / repo / "scripts/emit-dora-event.sh"
                )
            )
        },
    )
    assert g.rc == 1 and g.failed_with(
        "emit-dora-event.sh failed to emit deploy-marker"
    ), g.out
    assert "unknown argument: --deployment-intent" in g.out


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
    assert "skipped" in ANSI.sub("", g.out)
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
