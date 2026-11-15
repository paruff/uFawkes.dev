"""Run a uFawkesDojo grader against stand-ins for the stack it expects:
stub servers on the ports it hardcodes, stub docker/sleep/gh on PATH, and
one real dora-api shared by the whole run."""

import atexit
import base64
import json
import re
import tempfile
from collections.abc import Callable
from contextlib import ExitStack
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

import conftest

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


# The real dora-api, started on first use. grade() resets it, or stops it when
# a test needs :8088 down or stubbed; the next test that wants it restarts it.
api = RealDoraApi(Path(tempfile.mkdtemp(prefix="dora-api-")))
atexit.register(api.stop)


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
                if spec == "default":
                    api.start()
                    api.reset()
                    servers[name] = api
                    continue
                api.stop()
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
        queued = api.queued_events() if servers.get("dora") is api else 0
    return Graded(rc, out, servers, queued)


def env_file(creds: tuple[str, str] = CREDS) -> str:
    return f"GRAFANA_ADMIN_USER={creds[0]}\nGRAFANA_ADMIN_PASSWORD={creds[1]}\n"
