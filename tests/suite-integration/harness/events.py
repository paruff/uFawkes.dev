"""Mock event emitters: the four uFawkesObs DORA event types, valid by default.

Each builder returns a payload that passes its schema in
uFawkesObs/dora/events/. Keyword arguments override or add fields, so a test
states only what it is about. A value of None removes the field.
"""

from datetime import datetime

REPO = "acme/shop"


def sha(n: int) -> str:
    """A stable 40-hex commit SHA for the nth change."""
    return f"{n:040x}"


def iso(when: datetime) -> str:
    return when.strftime("%Y-%m-%dT%H:%M:%SZ")


def _event(base: dict, overrides: dict) -> dict:
    merged = {**base, **overrides}
    return {
        key: iso(value) if isinstance(value, datetime) else value
        for key, value in merged.items()
        if value is not None
    }


def deployment(
    n: int, deployed_at: datetime, status: str = "success", **overrides
) -> dict:
    return _event(
        {
            "schema_version": "1.0",
            "event_type": "deployment",
            "repo": REPO,
            "service": "shop",
            "environment": "production",
            "commit_sha": sha(n),
            "deployed_at": deployed_at,
            "status": status,
            "pipeline_url": f"https://ci.example.test/runs/{n}",
        },
        overrides,
    )


def incident(
    incident_id: str, occurred_at: datetime, status: str = "opened", **overrides
) -> dict:
    return _event(
        {
            "schema_version": "1.0",
            "event_type": "incident",
            "incident_id": incident_id,
            "repo": REPO,
            "service": "shop",
            "status": status,
            "occurred_at": occurred_at,
        },
        overrides,
    )


def pr(
    number: int,
    occurred_at: datetime,
    first_commit_at: datetime,
    status: str = "merged",
    **overrides,
) -> dict:
    return _event(
        {
            "schema_version": "1.0",
            "event_type": "pr",
            "repo": REPO,
            "pr_number": number,
            "commit_sha": sha(number),
            "status": status,
            "occurred_at": occurred_at,
            "first_commit_at": first_commit_at,
        },
        overrides,
    )


def rework(
    n: int,
    triggered_at: datetime,
    rework_type: str = "hotfix",
    user_visible: bool = True,
    **overrides,
) -> dict:
    """A rework event against the deployment of change n."""
    return _event(
        {
            "schema_version": "1.0",
            "event_type": "rework",
            "repo": REPO,
            "deployment_sha": sha(n),
            "rework_type": rework_type,
            "triggered_at": triggered_at,
            "user_visible": user_visible,
        },
        overrides,
    )
