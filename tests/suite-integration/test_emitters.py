"""The suite's real event emitters against the real uFawkesObs ingestion API."""

import asyncio
import hashlib
import importlib
import json
import re
import shutil
import sys
from datetime import UTC, datetime
from pathlib import Path

import httpx
import pytest
import yaml
from conftest import AI, DEVX, DOJO, FAWKES, FIXTURES, OBS, PIPE, SITE
from harness.shell import Result, curl_calls, curl_stub, run_script, stub_bin

SHA = "0123456789abcdef0123456789abcdef01234567"
AT = "2026-09-27T12:45:00Z"
EVENTS = ("deployment", "incident", "pr", "rework")
REPOS = {
    "fawkes": FAWKES,
    "uFawkesObs": OBS,
    "uFawkesPipe": PIPE,
    "uFawkesDevX": DEVX,
    "uFawkesDojo": DOJO,
    "uFawkesAI": AI,
    "uFawkes.dev": SITE,
}
AI_DRIFT = pytest.mark.finding("AF-12")
REPO_PARAMS = [
    pytest.param(n, marks=AI_DRIFT) if n == "uFawkesAI" else n for n in REPOS
]


def emit_script(repo: str) -> Path:
    return REPOS[repo] / "scripts" / "emit-dora-event.sh"


def github_env(repo: str) -> dict[str, str]:
    return {
        "GITHUB_REPOSITORY": f"acme/{repo}",
        "GITHUB_SHA": SHA,
        "GITHUB_RUN_ID": "9001",
        "GITHUB_RUN_NUMBER": "17",
        "GITHUB_JOB": "ci",
    }


WOODPECKER_ENV = {
    "CI_REPO": "acme/pipe-thing",
    "CI_REPO_NAME": "pipe-thing",
    "CI_COMMIT_SHA": SHA,
    "CI_PIPELINE_NUMBER": "5",
    "CI_PIPELINE_URL": "https://ci.test/repos/1/pipeline/5",
    "CI_STEP_NAME": "notify-obs",
}


def gh_stub(directory: Path) -> Path:
    fx = FIXTURES / "gh"
    stub_bin(
        directory,
        "gh",
        f"""case "$*" in
  */commits/*/pulls*) cat {fx}/pr_number.txt ;;
  *pulls/42/commits*) cat {fx}/commits.json ;;
  *pulls/42*) cat {fx}/pr.json ;;
  *) echo "unexpected gh call: $*" >&2; exit 1 ;;
esac""",
    )
    return directory


def emit(
    repo: str,
    args: list[str],
    env: dict[str, str],
    tmp: Path,
    gh: bool = True,
    script: Path | None = None,
) -> Result:
    return run_script(
        script or emit_script(repo),
        args,
        env,
        path_dir=gh_stub(tmp / "bin") if gh else None,
        tmp=tmp,
    )


def one_event(result: Result) -> dict:
    assert result.returncode == 0, result.stderr
    assert len(result.stdout.splitlines()) == 1, result.stdout
    return json.loads(result.stdout)


# ── Parity ───────────────────────────────────────────────────────────────────


@pytest.mark.parametrize(
    "repo",
    [
        pytest.param(n, marks=AI_DRIFT) if n == "uFawkesAI" else n
        for n in REPOS
        if n != "uFawkesObs"
    ],
)
def test_emit_script_identical_to_obs(repo: str) -> None:
    digest = lambda r: hashlib.md5(emit_script(r).read_bytes()).hexdigest()
    assert digest(repo) == digest("uFawkesObs")


@pytest.mark.parametrize(
    "event",
    [
        pytest.param(e, marks=pytest.mark.finding("AF-13")) if e == "deployment" else e
        for e in EVENTS
    ],
)
def test_pipe_schema_matches_obs(event: str) -> None:
    name = f"{event}-event.schema.json"
    assert json.loads(
        (PIPE / "contracts/dora-events" / name).read_text()
    ) == json.loads((OBS / "dora/events" / name).read_text())


def test_site_vendored_schema_matches_obs() -> None:
    vendored = json.loads(
        (SITE / "scripts/testdata/ufawkesobs-deployment-event.schema.json").read_text()
    )
    assert vendored == json.loads(
        (OBS / "dora/events/deployment-event.schema.json").read_text()
    )


# ── emit-dora-event.sh ───────────────────────────────────────────────────────


def post_and_count(obs, event: dict) -> dict:
    response = obs.post("/event", event)
    assert response.status_code == 201, response.text
    obs.drain()
    return obs.metrics()[event["repo"]]


@pytest.mark.parametrize("repo", REPO_PARAMS)
def test_github_deploy_marker_is_ingested_with_lead_time(
    repo: str, obs, tmp_path: Path
) -> None:
    line = one_event(
        emit(repo, ["deploy-marker", "--at", AT], github_env(repo), tmp_path)
    )
    assert line["dora_event"]["first_commit_at"] == "2026-09-27T08:15:00Z"
    metrics = post_and_count(obs, line["dora_event"])
    assert metrics["deployment_frequency"] > 0
    assert metrics["lead_time_p50_hours"] == 4.5  # 08:15 first commit -> 12:45


@pytest.mark.parametrize("repo", REPO_PARAMS)
def test_woodpecker_deploy_marker_without_gh_is_ingested(
    repo: str, obs, tmp_path: Path
) -> None:
    line = one_event(
        emit(repo, ["deploy-marker", "--at", AT], WOODPECKER_ENV, tmp_path, gh=False)
    )
    assert line["pr"] is None
    assert post_and_count(obs, line["dora_event"])["deployment_frequency"] > 0


@pytest.mark.parametrize("status", ["failure", "rollback"])
def test_failed_deploy_marker_counts_as_failed_change(
    status: str, obs, tmp_path: Path
) -> None:
    line = one_event(
        emit(
            "uFawkesObs",
            ["deploy-marker", "--at", AT, "--status", status],
            github_env("x"),
            tmp_path,
        )
    )
    metrics = post_and_count(obs, line["dora_event"])
    assert metrics["change_failure_rate"] == 1.0
    assert metrics["deployment_frequency"] is None


@pytest.mark.finding("AF-14")
def test_deploy_without_sha_or_pipeline_url_is_not_lost(obs, tmp_path: Path) -> None:
    # Copied out of the checkout so `git rev-parse HEAD` finds no repository.
    script = tmp_path / "scripts" / "emit-dora-event.sh"
    script.parent.mkdir()
    shutil.copy(emit_script("uFawkesObs"), script)
    result = emit(
        "",
        ["deploy-marker", "--at", AT],
        {"GITHUB_REPOSITORY": "acme/bare"},
        tmp_path,
        gh=False,
        script=script,
    )
    if result.returncode != 0:
        return  # refusing loudly is fine: the pipeline sees the failure
    response = obs.post("/event", json.loads(result.stdout)["dora_event"])
    assert response.status_code == 201, (
        f"emitter reported success, dora-api dropped it: {response.text}"
    )


@pytest.mark.parametrize("repo", list(REPOS))
def test_job_start_finish_duration(repo: str, tmp_path: Path) -> None:
    env = github_env(repo)
    one_event(
        emit(
            repo,
            ["job-start", "--step", "build", "--at", "2026-09-27T12:40:00Z"],
            env,
            tmp_path,
            gh=False,
        )
    )
    finish = one_event(
        emit(
            repo,
            ["job-finish", "--step", "build", "--at", "2026-09-27T12:47:30Z"],
            env,
            tmp_path,
            gh=False,
        )
    )
    assert finish["duration_ms"] == 450_000


def test_otlp_endpoint_down_still_emits(tmp_path: Path) -> None:
    env = {**github_env("x"), "OTEL_EXPORTER_OTLP_ENDPOINT": "http://127.0.0.1:1"}
    result = emit("uFawkesObs", ["deploy-marker", "--at", AT], env, tmp_path, gh=False)
    assert one_event(result)["event"] == "deploy-marker"
    assert "OTLP export" in result.stderr


def test_otlp_payload_carries_the_event_line(tmp_path: Path) -> None:
    stubs = tmp_path / "stubs"
    env = {
        **github_env("x"),
        **curl_stub(stubs),
        "OTEL_EXPORTER_OTLP_ENDPOINT": "http://otel.test:4318/",
    }
    result = run_script(
        emit_script("uFawkesObs"),
        ["deploy-marker", "--at", AT],
        env,
        path_dir=stubs,
        tmp=tmp_path,
    )
    (call,) = curl_calls(stubs)
    assert call.args[-1] == "http://otel.test:4318/v1/logs"
    record = json.loads(call.body)["resourceLogs"][0]["scopeLogs"][0]["logRecords"][0]
    assert record["body"]["stringValue"] == result.stdout.strip()
    assert record["timeUnixNano"] == str(
        int(datetime(2026, 9, 27, 12, 45, tzinfo=UTC).timestamp()) * 10**9
    )


@pytest.mark.finding("AF-15")
def test_deploy_marker_reaches_the_dora_api(tmp_path: Path) -> None:
    # dora-api is the only thing that turns a deployment into DORA metrics, and
    # nothing in uFawkesObs forwards the log line's dora_event to it.
    stubs = tmp_path / "stubs"
    env = {
        **github_env("x"),
        **curl_stub(stubs),
        "OTEL_EXPORTER_OTLP_ENDPOINT": "http://otel.test:4318",
        "DORA_INGESTION_URL": "http://dora.test:8088",
    }
    run_script(
        emit_script("uFawkesObs"),
        ["deploy-marker", "--at", AT],
        env,
        path_dir=stubs,
        tmp=tmp_path,
    )
    assert "http://dora.test:8088/event" in [
        call.args[-1] for call in curl_calls(stubs)
    ]


# ── uFawkesPipe notify-obs ───────────────────────────────────────────────────


def run_notify_obs(tmp: Path, env: dict[str, str]) -> tuple[Result, list]:
    pipeline = yaml.safe_load((PIPE / ".woodpecker.yml").read_text())
    step = next(s for s in pipeline["steps"] if s["name"] == "notify-obs")
    script = tmp / "notify-obs.sh"
    script.write_text(
        "#!/usr/bin/env bash\nset -e\n"
        + "\n".join(step["commands"]).replace("/drone/src", str(PIPE))
        + "\n"
    )
    script.chmod(0o755)
    stubs = tmp / "stubs"
    result = run_script(
        script,
        [],
        {**WOODPECKER_ENV, **curl_stub(stubs), **env},
        path_dir=stubs,
        tmp=tmp,
    )
    return result, curl_calls(stubs)


def test_notify_obs_event_is_ingested(obs, tmp_path: Path) -> None:
    result, calls = run_notify_obs(tmp_path, {"DORA_INGESTION_URL": "http://dora-api"})
    assert result.returncode == 0, result.stderr
    (call,) = calls
    assert "Authorization" not in " ".join(call.args)
    event = json.loads(call.body)
    assert post_and_count(obs, event)["deployment_frequency"] > 0


def test_notify_obs_without_url_warns_and_posts_nothing(tmp_path: Path) -> None:
    result, calls = run_notify_obs(tmp_path, {})
    assert result.returncode == 0, result.stderr
    assert calls == [] and "DORA_INGESTION_URL not set" in result.stdout


def test_notify_obs_sends_api_key(tmp_path: Path) -> None:
    _, calls = run_notify_obs(
        tmp_path, {"DORA_INGESTION_URL": "http://dora-api", "DORA_API_KEY": "k3y"}
    )
    assert "Authorization: Bearer k3y" in calls[0].args


# ── uFawkesObs's own collectors ──────────────────────────────────────────────

CURL_EXAMPLES = re.findall(
    r"(?ms)^# curl .*?^#   \}'$",
    (OBS / "dora/collectors/generic/curl-examples.sh").read_text(),
)
COLLECTOR_ENV = {
    "DORA_INGESTION_URL": "http://dora-api",
    "CI_REPO": "acme",
    "CI_REPO_NAME": "shop",
    "CI_COMMIT_SHA": SHA,
    "CI_PIPELINE_URL": "https://ci.test/runs/1",
}


def post_recorded(obs, calls: list) -> None:
    assert len(calls) == 1
    response = obs.post("/event", json.loads(calls[0].body))
    assert response.status_code == 201, response.text


def run_collector(
    script: Path, args: list[str], env: dict[str, str], tmp: Path
) -> list:
    stubs = tmp / "stubs"
    result = run_script(
        script,
        args,
        {**COLLECTOR_ENV, **curl_stub(stubs), **env},
        path_dir=stubs,
        tmp=tmp,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    return curl_calls(stubs)


def test_curl_examples_block_count() -> None:
    assert len(CURL_EXAMPLES) == 6


@pytest.mark.parametrize("index", range(6))
def test_curl_example_is_accepted(index: int, obs, tmp_path: Path) -> None:
    script = tmp_path / "example.sh"
    script.write_text(
        "#!/bin/sh\n" + re.sub(r"(?m)^# ?", "", CURL_EXAMPLES[index]) + "\n"
    )
    script.chmod(0o755)
    post_recorded(obs, run_collector(script, [], {}, tmp_path))


@pytest.mark.parametrize("status", ["success", "failed", "rollback"])
def test_send_dora_deployment_event_is_accepted(
    status: str, obs, tmp_path: Path
) -> None:
    env = {
        "DORA_REPO": "acme/shop",
        "DORA_SERVICE": "shop",
        "DORA_ENVIRONMENT": "production",
        "DORA_COMMIT_SHA": SHA,
        "DORA_STATUS": status,
        "DORA_PIPELINE_URL": "https://ci.test/runs/1",
        "DORA_PR_MERGED_AT": "2026-09-27T12:30:00Z",
        "DORA_FAILED_EVENTS_PATH": str(tmp_path / "failed.jsonl"),
    }
    post_recorded(
        obs,
        run_collector(OBS / "scripts/send-dora-deployment-event.sh", [], env, tmp_path),
    )


@pytest.mark.parametrize("script", ["declare-incident.sh", "resolve-incident.sh"])
def test_incident_collectors_are_accepted(script: str, obs, tmp_path: Path) -> None:
    args = [
        "--incident_id=INC-1",
        "--service=shop",
        "--severity=major",
        "--repo=acme/shop",
    ]
    post_recorded(
        obs,
        run_collector(
            OBS / "dora/collectors/manual-incident" / script, args, {}, tmp_path
        ),
    )


# ── fawkes dora-metrics service ──────────────────────────────────────────────


def test_fawkes_dora_metrics_gauges(monkeypatch: pytest.MonkeyPatch) -> None:
    service = FAWKES / "services/dora-metrics"
    pytest.importorskip("fastapi")
    monkeypatch.syspath_prepend(str(service))
    for name in [m for m in sys.modules if m == "app" or m.startswith("app.")]:
        monkeypatch.delitem(sys.modules, name)
    main = importlib.import_module("app.main")
    base = importlib.import_module("app.collectors.base")

    def pr(number: str, title: str, first: str, merged: str) -> object:
        parse = datetime.fromisoformat
        return base.MergedPR(
            number,
            title,
            parse(merged),
            "paruff/fawkes",
            [
                base.CommitInfo("a" * 40, "h", "", parse(first)),
                base.CommitInfo("b" * 40, "h", "", parse(merged)),
            ],
        )

    class Fake(base.RepoSourceCollector):
        def list_merged_prs(self, repo: str, since: datetime, until: datetime) -> list:
            return [
                pr(
                    "1",
                    "chore(main): release 1.0.0",
                    "2026-10-01T00:00:00+00:00",
                    "2026-10-01T10:00:00+00:00",
                ),
                pr(
                    "2",
                    "chore(main): release 1.1.0",
                    "2026-10-10T00:00:00+00:00",
                    "2026-10-10T04:00:00+00:00",
                ),
                pr(
                    "3",
                    "feat: not a release",
                    "2026-10-11T00:00:00+00:00",
                    "2026-10-11T01:00:00+00:00",
                ),
            ]

        def get_golden_path(self, repo: str) -> None:
            return None

    monkeypatch.setattr(main, "get_collector", lambda _name: Fake())
    monkeypatch.setattr(main, "WINDOW_DAYS", 30)
    monkeypatch.setattr(main, "_snapshot", None)
    main._refresh()  # one refresh cycle, run by hand: the app is served without its lifespan

    async def scrape() -> str:
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=main.app), base_url="http://svc"
        ) as client:
            return (await client.get("/metrics")).text

    body = asyncio.run(scrape())
    assert (
        f'fawkes_repo_deployment_frequency_per_day{{repo="paruff/fawkes"}} {2 / 30}'
        in body
    )
    assert 'fawkes_repo_lead_time_hours{repo="paruff/fawkes"} 7.0' in body
