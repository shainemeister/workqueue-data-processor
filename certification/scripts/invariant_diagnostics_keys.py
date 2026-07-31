"""Dynamic invariant: diagnostics result has no PHI/claim dump shapes."""

from __future__ import annotations

import sys
from pathlib import Path

# Allow `from _common import ...` when launched as py path/to/script.py
sys.path.insert(0, str(Path(__file__).resolve().parent))
from typing import Any

from _common import ensure_kpi_on_path, fail_exit, pass_exit

# Top-level keys currently emitted by run_diagnostics / write_reports.
ALLOWED_TOP_LEVEL = frozenset(
    {
        "ReportVersion",
        "Success",
        "OverallPass",
        "Command",
        "Version",
        "ToolkitVersion",
        "PythonVersion",
        "PythonExecutable",
        "Platform",
        "StartedAt",
        "FinishedAt",
        "ToolkitRoot",
        "CriticalFailed",
        "Checks",
        "Message",
        "ReportJsonPath",
        "ReportTextPath",
    }
)

# Keys that must never appear anywhere in the diagnostics tree.
DENY_KEYS = frozenset(
    {
        "patient",
        "dob",
        "date of birth",
        "ssn",
        "rows",
        "claims",
        "records",
        "data",
        "password",
        "secret",
        "mrn",
    }
)


def _walk(obj: Any, path: str, issues: list[str]) -> None:
    if isinstance(obj, dict):
        for key, value in obj.items():
            key_s = str(key)
            key_l = key_s.lower()
            here = f"{path}.{key_s}" if path else key_s
            if key_l in DENY_KEYS:
                issues.append(f"deny_key:{here}")
                continue
            _walk(value, here, issues)
    elif isinstance(obj, list):
        # Claim-table shape: list of dicts with many row-like keys — flag deny keys only
        for idx, item in enumerate(obj):
            _walk(item, f"{path}[{idx}]", issues)


def main() -> None:
    ensure_kpi_on_path()
    from kpi_modules.diagnostics import run_diagnostics

    result = run_diagnostics(write=False)
    if not isinstance(result, dict):
        fail_exit("diagnostics result not a dict")

    unknown = sorted(set(result.keys()) - ALLOWED_TOP_LEVEL)
    if unknown:
        # Report key names only (no values)
        fail_exit(f"unexpected top-level keys: {','.join(unknown[:8])}")

    issues: list[str] = []
    _walk(result, "", issues)
    if issues:
        fail_exit(f"deny keys in tree: {','.join(issues[:6])}")

    checks = result.get("Checks") or []
    pass_exit(
        f"diagnostics keys ok; top_level={len(result)}; "
        f"checks={len(checks)}; no_phi_keys"
    )


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail_exit(f"invariant_diagnostics_keys error: {type(exc).__name__}")
