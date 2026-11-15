"""Offline stand-ins for what the Dojo graders talk to: HTTP servers on the
exact loopback ports they hardcode, and bash stubs for docker/sleep/gh.

Everything here is deterministic. The only wait is the bounded readiness
loop of RealDoraApi.start.
"""

import contextlib
import json
import os
import sqlite3
import subprocess
import sys
import threading
import time
import urllib.request
from collections.abc import Callable
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, Self

import conftest

Response = tuple[
    int, Any, str
]  # (status, body: str | bytes | dict | list, content_type)


@dataclass(frozen=True)
class Request:
    method: str
    path: str  # includes the query string
    headers: dict[str, str]
    body: bytes

    @property
    def text(self) -> str:
        return self.body.decode("utf-8", "replace")


Handler = Callable[[Request], Response]
Routes = dict[tuple[str, str], Response]


def _routes_handler(routes: Routes) -> Handler:
    def handle(req: Request) -> Response:
        path = req.path.split("?", 1)[0]
        hits = [
            (len(prefix), resp)
            for (method, prefix), resp in routes.items()
            if method == req.method and path.startswith(prefix)
        ]
        return (
            max(hits, key=lambda hit: hit[0])[1]
            if hits
            else (404, "not found", "text/plain")
        )

    return handle


class _Server(ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True


class StubServer:
    """HTTP server on 127.0.0.1:<port>, listening as soon as the constructor returns.

    routes is {(method, path_prefix): (status, body, content_type)} (longest
    prefix wins, unmatched is 404) or a callable Request -> (status, body,
    content_type). Every request is appended to .requests.
    """

    def __init__(self, port: int, routes: Routes | Handler) -> None:
        self.port = port
        self.requests: list[Request] = []
        handle = routes if callable(routes) else _routes_handler(routes)
        outer = self

        class _Handler(BaseHTTPRequestHandler):
            def _serve(self) -> None:
                length = int(self.headers.get("Content-Length") or 0)
                req = Request(
                    self.command, self.path, dict(self.headers), self.rfile.read(length)
                )
                outer.requests.append(req)
                status, body, ctype = handle(req)
                if isinstance(body, dict | list):
                    body = json.dumps(body)
                raw = body.encode() if isinstance(body, str) else body
                self.send_response(status)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(raw)))
                self.end_headers()
                self.wfile.write(raw)

            do_GET = do_POST = do_PUT = do_DELETE = _serve

            def log_message(self, *args: Any) -> None:
                pass

        self._server = _Server(("127.0.0.1", port), _Handler)  # binds and listens
        self._thread = threading.Thread(target=self._server.serve_forever, daemon=True)

    def __enter__(self) -> Self:
        self._thread.start()
        return self

    def __exit__(self, *exc: object) -> None:
        self._server.shutdown()
        self._server.server_close()
        self._thread.join()


def stub_bin(directory: Path, name: str, script: str) -> Path:
    """Write an executable bash stub; put `directory` first on PATH to use it."""
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / name
    path.write_text(f"#!/usr/bin/env bash\n{script}\n")
    path.chmod(0o755)
    return path


def docker_stub(
    directory: Path, running: set[str], health: dict[str, str] | None = None
) -> Path:
    """`docker ps [--filter name=^X$] --format ...` prints the running names
    (just X when filtered); `docker inspect ... X` prints X's health, or
    "none" for a container without one."""
    health_cases = "".join(
        f"    {n}) echo {h};;\n" for n, h in sorted((health or {}).items())
    )
    running_list = " ".join(sorted(running))
    # The names go out in one write, as the real docker CLI's do: the external
    # printf, because bash's builtin flushes at every newline. A grader that
    # pipes this into `grep -q` under pipefail otherwise races the stub (AF-24).
    return stub_bin(
        directory,
        "docker",
        f"""running=({running_list})
case "$1" in
  ps)
    want=""
    for a in "$@"; do case "$a" in name=^*) want="${{a#name=^}}"; want="${{want%\\$}}";; esac; done
    out=""
    for n in "${{running[@]}}"; do
      if [ -z "$want" ] || [ "$n" = "$want" ]; then out+="$n"$'\\n'; fi
    done
    /usr/bin/printf '%s' "$out";;
  inspect)
    case "${{@: -1}}" in
{health_cases}    *) echo none;;
    esac;;
  *) echo "docker stub: unsupported $*" >&2; exit 1;;
esac""",
    )


class RealDoraApi:
    """The real uFawkesObs dora-api as a subprocess on 127.0.0.1:<port>.

    Started once and reused: reset() empties its tables between tests, which
    is cheaper and steadier than a Python start-up per test. It runs without
    its lifespan, so without the background worker: the graders only need the HTTP API.
    """

    def __init__(self, work_dir: Path, port: int = 8088) -> None:
        self.url = f"http://127.0.0.1:{port}"
        self.db_path = work_dir / "dora.db"
        self._log_path = work_dir / "dora-api.log"
        self._port = port
        self._proc: subprocess.Popen | None = None

    def start(self) -> None:
        if self._proc is not None:
            return
        root = conftest.OBS / "dora"
        env = {
            **os.environ,
            "PYTHONPATH": str(root),
            "DATABASE_URL": f"sqlite:///{self.db_path}",
            "DORA_COMPUTE_INTERVAL_SECONDS": "3600",
        }
        env.pop("DORA_API_KEY", None)
        with self._log_path.open("wb") as log:
            self._proc = subprocess.Popen(
                [
                    sys.executable,
                    "-m",
                    "uvicorn",
                    "ingestion.api.main:app",
                    "--host",
                    "127.0.0.1",
                    "--port",
                    str(self._port),
                    "--lifespan",
                    "off",
                ],
                cwd=root,
                env=env,
                stdout=log,
                stderr=subprocess.STDOUT,
            )
        # The one bounded wait in the harness: the process is up when /health answers.
        deadline = time.monotonic() + 60
        while True:
            try:
                with urllib.request.urlopen(f"{self.url}/health", timeout=1):
                    return
            except OSError:
                if self._proc.poll() is not None or time.monotonic() > deadline:
                    log_text = self._log_path.read_text()
                    self.stop()
                    raise RuntimeError(
                        f"real dora-api did not come up on :{self._port}:\n{log_text}"
                    ) from None
                time.sleep(0.05)

    def stop(self) -> None:
        """Free the port, for a test that needs dora-api down or replaced."""
        if self._proc is not None:
            self._proc.kill()
            self._proc.wait()
            self._proc = None

    def queued_events(self) -> int:
        with contextlib.closing(sqlite3.connect(self.db_path, timeout=10)) as conn:
            return conn.execute("SELECT count(*) FROM event_queue").fetchone()[0]

    def reset(self) -> None:
        with (
            contextlib.closing(sqlite3.connect(self.db_path, timeout=10)) as conn,
            conn,
        ):
            for table in ("raw_events", "event_queue"):
                conn.execute(f"DELETE FROM {table}")


def run_grader(
    script: Path, env: dict[str, str], cwd: Path, path_dir: Path
) -> tuple[int, str]:
    """Run a bash grader with `path_dir` first on PATH. Returns (returncode, stdout+stderr)."""
    tmpdir = path_dir / "tmp"
    tmpdir.mkdir(parents=True, exist_ok=True)
    full_env = {
        "PATH": f"{path_dir}:{os.environ['PATH']}",
        "HOME": str(tmpdir),
        "TMPDIR": str(tmpdir),
        **env,
    }
    done = subprocess.run(
        ["bash", str(script)],
        check=False,
        env=full_env,
        cwd=cwd,
        capture_output=True,
        text=True,
        timeout=60,
    )
    return done.returncode, done.stdout + done.stderr
