"""Contract of the uFawkesObs ingestion API: what it accepts, rejects, dedupes and gates."""

import json
import sqlite3
from typing import Any

import conftest
import pytest
from harness import events
from jsonschema import Draft7Validator

Case = dict[str, Any]


def _load(name: str) -> list[Case]:
    return json.loads((conftest.FIXTURES / "events" / name).read_text())


VALID = _load("valid.json")
INVALID = _load("invalid.json")
VALID_PARAMS = [pytest.param(c, id=c["name"]) for c in VALID]
INVALID_PARAMS = [pytest.param(c, id=c["name"]) for c in INVALID]

# Independent restatement of the documented status -> outcome mapping.
OUTCOMES = {"success": "success", "failed": "failure", "rollback": "rollback"}


def _expected_outcome(payload: dict) -> str:
    kind, status = payload["event_type"], payload.get("status")
    if kind == "deployment":
        return OUTCOMES[status]
    if kind == "incident":
        return "success" if status == "resolved" else "unknown"
    if kind == "pr":
        return "success" if status == "merged" else "unknown"
    return "success"  # rework


def _schema_errors(payload: dict) -> list:
    path = (
        conftest.OBS / "dora" / "events" / f"{payload['event_type']}-event.schema.json"
    )
    # No format_checker: the API additionally enforces date-time, the bare schema does not.
    return list(Draft7Validator(json.loads(path.read_text())).iter_errors(payload))


def _queue_rows(obs) -> int:
    obs.get(
        "/health"
    )  # the schema is created lazily on first DB use; a rejected request never touches it
    return obs.sql("SELECT COUNT(*) FROM event_queue")[0][0]


def test_fixtures_cover_every_event_type() -> None:
    assert {c["payload"]["event_type"] for c in VALID} == {
        "deployment",
        "incident",
        "pr",
        "rework",
    }
    assert len(VALID) >= 8


# ── valid / invalid payloads ───────────────────────────────────────────────────


@pytest.mark.parametrize("case", VALID_PARAMS)
def test_valid_payload_is_queued_and_processed(obs, case: Case) -> None:
    payload = case["payload"]
    response = obs.post("/event", payload)
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["queued"] is True and isinstance(body["id"], int)

    assert obs.drain() == 1
    rows = obs.sql(
        "SELECT event_type, outcome, metadata, event_queue_id FROM raw_events"
    )
    assert len(rows) == 1
    event_type, outcome, metadata, queue_id = rows[0]
    assert (event_type, queue_id) == (payload["event_type"], body["id"])
    assert json.loads(metadata) == payload
    assert outcome == _expected_outcome(payload)


@pytest.mark.parametrize("case", VALID_PARAMS)
def test_valid_payload_passes_bare_schema(case: Case) -> None:
    assert _schema_errors(case["payload"]) == []


@pytest.mark.parametrize("case", INVALID_PARAMS)
def test_invalid_payload_is_rejected_and_not_queued(obs, case: Case) -> None:
    response = obs.post("/event", case["payload"])
    assert response.status_code == 422, response.text
    assert case["expect_field"] in json.dumps(response.json()["detail"])
    assert _queue_rows(obs) == 0


@pytest.mark.parametrize(
    "case", [p for p in INVALID_PARAMS if not p.values[0].get("no_schema")]
)
def test_invalid_payload_fails_bare_schema_unless_format_only(case: Case) -> None:
    errors = _schema_errors(case["payload"])
    if case.get("format_only"):
        # The API rejects these only through its date-time FormatChecker.
        assert errors == []
    else:
        assert errors


@pytest.mark.finding("AF-09")
@pytest.mark.parametrize(
    "case",
    [
        p
        for p in INVALID_PARAMS
        if "-missing-" in p.values[0]["name"]
        and p.values[0]["expect_field"] != "event_type"
    ],
)
def test_missing_required_field_is_named_in_the_error_location(obs, case: Case) -> None:
    # A client reads `loc` to find the field, as it can for every other kind of error.
    detail = obs.post("/event", case["payload"]).json()["detail"]
    assert ["body", case["expect_field"]] in [d["loc"] for d in detail]


@pytest.mark.finding("AF-10")
def test_pipeline_url_that_is_not_a_uri_is_rejected(obs, now) -> None:
    # The schema declares format: uri; dashboards link to this value.
    assert (
        obs.post(
            "/event", events.deployment(1, now, pipeline_url="not a uri")
        ).status_code
        == 422
    )


# ── batch ──────────────────────────────────────────────────────────────────────


def test_batch_valid_returns_ids_in_order(obs) -> None:
    payloads = [c["payload"] for c in VALID[:4]]
    response = obs.post("/event/batch", payloads)
    assert response.status_code == 201, response.text
    ids = response.json()["ids"]
    assert response.json()["queued"] is True and len(ids) == 4
    stored = obs.sql("SELECT id, payload FROM event_queue ORDER BY id")
    assert [i for i, _ in stored] == ids
    assert [json.loads(p) for _, p in stored] == payloads


@pytest.mark.parametrize("bad_index", [0, 1, 2])
def test_batch_with_one_invalid_enqueues_nothing(obs, bad_index: int) -> None:
    payloads = [c["payload"] for c in VALID[:3]]
    payloads[bad_index] = {
        **payloads[bad_index],
        "status": "bogus",
        "rework_type": "bogus",
    }
    payloads[bad_index]["event_type"] = "deployment"
    response = obs.post("/event/batch", payloads)
    assert response.status_code == 422, response.text
    assert list(response.json()["detail"]["errors"]) == [str(bad_index)]
    assert _queue_rows(obs) == 0


def test_batch_empty_list_is_accepted_and_enqueues_nothing(obs) -> None:
    response = obs.post("/event/batch", [])
    assert response.status_code == 201
    assert response.json() == {"queued": True, "ids": []}
    assert _queue_rows(obs) == 0


# ── idempotency ────────────────────────────────────────────────────────────────


def test_same_payload_twice_dedupes(obs) -> None:
    payload = VALID[0]["payload"]
    first, second = obs.post("/event", payload), obs.post("/event", payload)
    assert first.status_code == second.status_code == 201
    assert first.json()["id"] == second.json()["id"]
    assert _queue_rows(obs) == 1


def test_key_order_does_not_defeat_dedupe(obs) -> None:
    payload = VALID[0]["payload"]
    first = obs.post("/event", payload)
    second = obs.post("/event", dict(reversed(list(payload.items()))))
    assert first.json()["id"] == second.json()["id"]
    assert _queue_rows(obs) == 1


def test_one_differing_field_does_not_dedupe(obs) -> None:
    payload = VALID[0]["payload"]
    first = obs.post("/event", payload)
    second = obs.post("/event", {**payload, "service": "other"})
    assert first.json()["id"] != second.json()["id"]
    assert _queue_rows(obs) == 2


# ── auth ───────────────────────────────────────────────────────────────────────

KEY = "s3cret-token"


@pytest.mark.parametrize(
    "headers",
    [
        {},
        {"Authorization": "Bearer wrong"},
        {"Authorization": KEY},
        {"Authorization": f"Basic {KEY}"},
    ],
    ids=["no-header", "wrong-token", "missing-bearer-prefix", "wrong-scheme"],
)
@pytest.mark.parametrize("path", ["/event", "/event/batch"])
def test_bad_credentials_get_401_and_enqueue_nothing(
    obs, monkeypatch, path: str, headers: dict
) -> None:
    monkeypatch.setenv("DORA_API_KEY", KEY)
    payload = VALID[0]["payload"]
    response = obs.post(
        path, [payload] if path.endswith("batch") else payload, headers=headers
    )
    assert response.status_code == 401
    assert _queue_rows(obs) == 0


def test_right_token_is_accepted(obs, monkeypatch) -> None:
    monkeypatch.setenv("DORA_API_KEY", KEY)
    response = obs.post(
        "/event", VALID[0]["payload"], headers={"Authorization": f"Bearer {KEY}"}
    )
    assert response.status_code == 201
    assert _queue_rows(obs) == 1


@pytest.mark.parametrize("path", ["/health", "/metrics"])
def test_health_and_metrics_stay_open(obs, monkeypatch, path: str) -> None:
    monkeypatch.setenv("DORA_API_KEY", KEY)
    assert obs.get(path).status_code == 200


# ── health ─────────────────────────────────────────────────────────────────────


def test_queue_depth_tracks_pending_events(obs, now) -> None:
    assert obs.get("/health").json()["queue_depth"] == 0
    for n in range(3):
        assert obs.post("/event", events.deployment(n, now)).status_code == 201
    assert obs.get("/health").json() == {"status": "ok", "queue_depth": 3}
    assert obs.drain() == 3
    assert obs.get("/health").json()["queue_depth"] == 0


# ── worker ─────────────────────────────────────────────────────────────────────


def test_redelivery_of_a_processed_event_is_not_counted_twice(obs, now) -> None:
    event = events.deployment(1, now)
    assert obs.deliver(event) == obs.deliver(event)
    assert obs.sql("SELECT COUNT(*) FROM raw_events") == [(1,)]


@pytest.mark.finding("AF-11")
def test_event_claimed_by_a_worker_that_died_is_processed_after_restart(
    obs, now
) -> None:
    assert obs.post("/event", events.deployment(1, now)).status_code == 201
    assert obs.claim() is not None  # the worker took it, then the container was killed

    obs.drain()  # the worker after a restart
    assert obs.sql("SELECT COUNT(*) FROM raw_events") == [(1,)]


@pytest.mark.finding("AF-23", raises=sqlite3.OperationalError)
def test_event_posted_while_the_worker_is_claiming_another_is_accepted(
    obs, now
) -> None:
    assert obs.post("/event", events.deployment(1, now)).status_code == 201
    obs.worker_mid_dequeue()

    assert obs.post("/event", events.deployment(2, now)).status_code == 201
