"""Missing SBOMs and Cosign signatures: a change that was not attested must
not be recorded as a successful deployment.

uFawkesPipe's own pipeline (.woodpecker.yml) is the reference golden path, so
these tests run its real step commands with stubbed tools and check its graph.
"""

import os
import subprocess
from pathlib import Path

import conftest
import pytest
import yaml

PIPELINE = yaml.safe_load((conftest.PIPE / ".woodpecker.yml").read_text())
STEPS = {step["name"]: step for step in PIPELINE["steps"]}


def ancestors(step: str) -> set[str]:
    """Every step that must succeed before this one starts."""
    seen: set[str] = set()
    todo = list(STEPS[step].get("depends_on", []))
    while todo:
        name = todo.pop()
        if name not in seen:
            seen.add(name)
            todo.extend(STEPS[name].get("depends_on", []))
    return seen


def run_step(
    name: str, tmp_path: Path, tools: dict[str, int]
) -> subprocess.CompletedProcess:
    """Run a step's real commands the way Woodpecker does (one `sh -e` script).

    tools maps a tool name to the exit code its stub returns.
    """
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    for tool, code in tools.items():
        stub = bin_dir / tool
        stub.write_text(f"#!/bin/sh\nexit {code}\n")
        stub.chmod(0o755)
    script = "\n".join(STEPS[name]["commands"]).replace(
        "/drone/src", str(conftest.PIPE)
    )
    env = {
        "PATH": f"{bin_dir}:{os.environ['PATH']}",
        "CI_STEP_NAME": name,
        "CI_REPO": "acme/shop",
        "CI_REPO_NAME": "shop",
        "CI_COMMIT_SHA": "a" * 40,
        "CI_PIPELINE_NUMBER": "7",
        "REGISTRY_USERNAME": "acme",
    }
    return subprocess.run(
        ["bash", "-e", "-c", script],
        check=False,
        cwd=tmp_path,
        env=env,
        capture_output=True,
        text=True,
        timeout=60,
    )


@pytest.mark.parametrize(
    ("step", "tool"), [("generate-sbom", "trivy"), ("sign-image", "cosign")]
)
def test_attestation_step_fails_the_pipeline_when_its_tool_fails(
    step: str, tool: str, tmp_path: Path
) -> None:
    result = run_step(step, tmp_path, {tool: 1})

    assert result.returncode != 0
    assert '"level":"error"' in result.stdout.replace(" ", "")


@pytest.mark.parametrize(
    ("step", "tool"), [("generate-sbom", "trivy"), ("sign-image", "cosign")]
)
def test_attestation_step_passes_when_its_tool_succeeds(
    step: str, tool: str, tmp_path: Path
) -> None:
    result = run_step(step, tmp_path, {tool: 0})

    assert result.returncode == 0, result.stderr
    assert '"level":"error"' not in result.stdout.replace(" ", "")


@pytest.mark.finding("AF-07")
@pytest.mark.parametrize("gate", ["generate-sbom", "sign-image"])
def test_deployment_event_is_only_sent_after_the_image_is_attested(gate: str) -> None:
    assert gate in ancestors("notify-obs")


def test_deployment_event_waits_for_the_scans_and_the_build() -> None:
    assert {
        "vuln-scan-image",
        "secrets-scan",
        "policy-check",
        "build-image",
    } <= ancestors("notify-obs")


@pytest.mark.finding("AF-08")
def test_no_pipeline_step_runs_an_unpinned_latest_image() -> None:
    unpinned = sorted(
        name for name, step in STEPS.items() if step["image"].endswith(":latest")
    )

    assert unpinned == []
