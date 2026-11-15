"""Edge cases for DORA event capture, end to end through the real dora-api:
events that arrive late or out of order, failed canaries and their rollbacks,
malformed timestamps and non-production deployments.

Every test asserts the correct result. Where dora-api gets it wrong today the
test carries a `finding` mark naming its entry in AUDIT_FINDINGS.md.
"""

from datetime import datetime, timedelta

import pytest
from harness.events import REPO, deployment, iso
from harness.obs import ObsStack

WEEKS_IN_WINDOW = 30 / 7


def hours(n: float) -> timedelta:
    return timedelta(hours=n)


# ── Late and out-of-order delivery ───────────────────────────────────────────


def test_recovery_time_when_events_arrive_as_they_happen(
    obs: ObsStack, now: datetime
) -> None:
    failed_at, recovered_at = now - hours(5), now - hours(3)
    obs.deliver(deployment(1, failed_at, "failed"), ingested_at=failed_at)
    obs.deliver(deployment(2, recovered_at), ingested_at=recovered_at)

    assert obs.metrics()[REPO]["fdrt_p50_hours"] == pytest.approx(2.0)


@pytest.mark.finding("AF-01")
def test_recovery_time_when_the_recovery_arrives_before_the_failure(
    obs: ObsStack, now: datetime
) -> None:
    failed_at, recovered_at = now - hours(5), now - hours(3)
    obs.deliver(deployment(2, recovered_at), ingested_at=now - hours(1))
    obs.deliver(deployment(1, failed_at, "failed"), ingested_at=now)

    assert obs.metrics()[REPO]["fdrt_p50_hours"] == pytest.approx(2.0)


@pytest.mark.finding("AF-01")
def test_recovery_time_when_both_events_arrive_in_one_burst(
    obs: ObsStack, now: datetime
) -> None:
    # A CI retry or a backfill delivers hours of history within one second.
    obs.deliver(deployment(1, now - hours(5), "failed"), ingested_at=now)
    obs.deliver(deployment(2, now - hours(3)), ingested_at=now)

    assert obs.metrics()[REPO]["fdrt_p50_hours"] == pytest.approx(2.0)


@pytest.mark.finding("AF-01")
def test_deployment_older_than_the_window_is_not_counted_when_delivered_late(
    obs: ObsStack, now: datetime
) -> None:
    obs.deliver(deployment(1, now - timedelta(days=90)))

    frequency = obs.metrics(window_days=30).get(REPO, {}).get("deployment_frequency")
    assert not frequency


def test_deployment_inside_the_window_is_counted(obs: ObsStack, now: datetime) -> None:
    obs.deliver(deployment(1, now - timedelta(days=2)))

    assert obs.metrics(window_days=30)[REPO]["deployment_frequency"] == pytest.approx(
        1 / WEEKS_IN_WINDOW
    )


@pytest.mark.finding("AF-02")
def test_retry_that_adds_an_optional_field_is_still_one_deployment(
    obs: ObsStack, now: datetime
) -> None:
    deployed_at = now - hours(2)
    obs.deliver(deployment(1, deployed_at))
    obs.deliver(deployment(1, deployed_at, deploy_duration_seconds=42))

    assert obs.metrics()[REPO]["deployment_frequency"] == pytest.approx(
        1 / WEEKS_IN_WINDOW
    )


# ── Failed canaries and rollbacks ────────────────────────────────────────────


def _canary_story(obs: ObsStack, now: datetime) -> None:
    """Change 1 ships. Change 2's canary fails and is rolled back. Change 3 fixes it."""
    for event in (
        deployment(1, now - hours(10)),
        deployment(2, now - hours(6), "failed"),
        deployment(2, now - hours(5.5), "rollback"),
        deployment(3, now - hours(4)),
    ):
        obs.deliver(event, ingested_at=datetime.fromisoformat(event["deployed_at"]))


@pytest.mark.finding("AF-03")
def test_failed_canary_and_its_rollback_are_one_failed_change(
    obs: ObsStack, now: datetime
) -> None:
    _canary_story(obs, now)

    assert obs.metrics()[REPO]["change_failure_rate"] == pytest.approx(1 / 3)


@pytest.mark.finding("AF-03")
def test_recovery_time_runs_from_the_failed_canary_not_from_its_rollback(
    obs: ObsStack, now: datetime
) -> None:
    _canary_story(obs, now)

    assert obs.metrics()[REPO]["fdrt_p50_hours"] == pytest.approx(2.0)


def test_failed_canary_and_rollback_are_not_successful_deployments(
    obs: ObsStack, now: datetime
) -> None:
    _canary_story(obs, now)

    assert obs.metrics()[REPO]["deployment_frequency"] == pytest.approx(
        2 / WEEKS_IN_WINDOW
    )


def test_rollback_with_no_later_success_has_no_recovery_time(
    obs: ObsStack, now: datetime
) -> None:
    obs.deliver(deployment(1, now - hours(3)), ingested_at=now - hours(3))
    obs.deliver(deployment(2, now - hours(2), "rollback"), ingested_at=now - hours(2))

    record = obs.metrics()[REPO]
    assert record["fdrt_p50_hours"] is None
    assert record["dora_tier_fdrt"] == "unknown"
    assert record["change_failure_rate"] == pytest.approx(0.5)


def test_recovery_in_another_repo_does_not_close_this_repos_failure(
    obs: ObsStack, now: datetime
) -> None:
    obs.deliver(deployment(1, now - hours(5), "failed"), ingested_at=now - hours(5))
    obs.deliver(
        deployment(2, now - hours(3), repo="acme/other"), ingested_at=now - hours(3)
    )

    assert obs.metrics()[REPO]["fdrt_p50_hours"] is None


@pytest.mark.finding("AF-04")
def test_failed_staging_deployment_does_not_count_against_production(
    obs: ObsStack, now: datetime
) -> None:
    obs.deliver(deployment(1, now - hours(3)))
    obs.deliver(deployment(2, now - hours(2), "failed", environment="staging"))

    record = obs.metrics()[REPO]
    assert record["change_failure_rate"] == 0
    assert record["deployment_frequency"] == pytest.approx(1 / WEEKS_IN_WINDOW)


# ── Timestamps ───────────────────────────────────────────────────────────────


def test_lead_time_across_utc_offsets(obs: ObsStack, now: datetime) -> None:
    first_commit = now - hours(6)
    local = (first_commit + hours(2)).strftime("%Y-%m-%dT%H:%M:%S") + "+02:00"
    obs.deliver(deployment(1, now, first_commit_at=local))

    assert obs.metrics()[REPO]["lead_time_p50_hours"] == pytest.approx(6.0)


@pytest.mark.finding("AF-05")
@pytest.mark.parametrize("field", ["deployed_at", "first_commit_at"])
@pytest.mark.parametrize(
    "value", ["2026-11-10T10:00:00", "2026-11-10"], ids=["no-offset", "date-only"]
)
def test_timestamp_without_a_utc_offset_is_rejected(
    obs: ObsStack, now: datetime, field: str, value: str
) -> None:
    event = {**deployment(1, now, first_commit_at=now - hours(1)), field: value}

    assert obs.post("/event", event).status_code == 422


@pytest.mark.finding("AF-05")
def test_one_event_with_a_naive_timestamp_does_not_stop_metrics_for_every_team(
    obs: ObsStack, now: datetime
) -> None:
    obs.deliver(
        deployment(
            1, now - hours(1), repo="acme/healthy", first_commit_at=now - hours(3)
        )
    )
    naive = (now - hours(2)).strftime("%Y-%m-%dT%H:%M:%S")
    response = obs.post(
        "/event",
        deployment(2, now - hours(1), repo="acme/sloppy", first_commit_at=naive),
    )
    obs.drain()

    assert response.status_code == 422 or obs.metrics()["acme/healthy"][
        "lead_time_p50_hours"
    ] == pytest.approx(2.0)


@pytest.mark.finding("AF-06")
def test_first_commit_after_the_deployment_cannot_yield_a_negative_lead_time(
    obs: ObsStack, now: datetime
) -> None:
    response = obs.post(
        "/event", deployment(1, now - hours(5), first_commit_at=now - hours(1))
    )
    obs.drain()

    lead_time = obs.metrics().get(REPO, {}).get("lead_time_p50_hours")
    assert response.status_code == 422 or lead_time is None or lead_time >= 0


@pytest.mark.finding("AF-06")
def test_deployment_dated_in_the_future_is_rejected(
    obs: ObsStack, now: datetime
) -> None:
    assert (
        obs.post("/event", deployment(1, now + timedelta(days=365))).status_code == 422
    )


def test_metrics_endpoint_text_matches_a_compute_cycle(
    obs: ObsStack, now: datetime
) -> None:
    from compute.metrics import render_prometheus_text

    obs.deliver(deployment(1, now - hours(1), first_commit_at=iso(now - hours(3))))
    text = render_prometheus_text(list(obs.metrics().values()))

    assert (
        f'dora_lead_time_p50_hours{{team_id="{REPO}",tier="high"}} 2.0'
        in text.splitlines()
    )
    assert text.count("# TYPE dora_deployment_frequency_per_week gauge") == 1
