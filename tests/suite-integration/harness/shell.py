"""Run the suite's real shell scripts hermetically, with stub binaries on PATH."""

import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from harness.stubs import stub_bin

SYSTEM_PATH = "/usr/local/bin:/usr/bin:/bin"

# Records every call as <n>.args (one argument per line) and <n>.body (the -d
# value) in $CURL_STUB_DIR, and answers with $CURL_STUB_CODE (default 201)
# when the caller asked for -w (otherwise silently).
CURL_STUB = r"""
d="${CURL_STUB_DIR:?}"; n=0
while [ -e "$d/$n.args" ]; do n=$((n + 1)); done
printf '%s\n' "$@" > "$d/$n.args"; : > "$d/$n.body"
want_code=0
while [ $# -gt 0 ]; do
  case "$1" in
    -d) printf '%s' "$2" > "$d/$n.body"; shift ;;
    -w) want_code=1; shift ;;
    -H|-X|-o|--max-time|--connect-timeout) shift ;;
  esac
  shift
done
[ "$want_code" = 1 ] && printf '%s' "${CURL_STUB_CODE:-201}"
exit 0
"""


@dataclass(frozen=True)
class Result:
    returncode: int
    stdout: str
    stderr: str


@dataclass(frozen=True)
class CurlCall:
    args: list[str]
    body: str


def curl_stub(directory: Path, code: int = 201) -> dict[str, str]:
    """Install the recording curl in directory; returns the env it needs."""
    stub_bin(directory, "curl", CURL_STUB)
    return {"CURL_STUB_DIR": str(directory), "CURL_STUB_CODE": str(code)}


def curl_calls(directory: Path) -> list[CurlCall]:
    calls = []
    for n in range(len(list(directory.glob("*.args")))):
        args = (directory / f"{n}.args").read_text().splitlines()
        calls.append(CurlCall(args, (directory / f"{n}.body").read_text()))
    return calls


def run_script(
    script: Path,
    args: list[str] | tuple[str, ...] = (),
    env: dict[str, str] | None = None,
    cwd: Path | None = None,
    path_dir: Path | None = None,
    tmp: Path | None = None,
) -> Result:
    """Run script with a minimal fixed environment (no inherited CI variables).

    env entries win over the defaults, so a test can pin RUNNER_TEMP to share
    state between two runs. path_dir goes first on PATH.
    """
    with tempfile.TemporaryDirectory() as fallback:
        work = str(tmp or fallback)
        full_env = {
            "PATH": f"{path_dir}:{SYSTEM_PATH}" if path_dir else SYSTEM_PATH,
            "HOME": work,
            "TMPDIR": work,
            "RUNNER_TEMP": work,
            "LANG": "C.UTF-8",
            **(env or {}),
        }
        done = subprocess.run(
            [str(script), *args],
            env=full_env,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
    return Result(done.returncode, done.stdout, done.stderr)
