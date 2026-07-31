"""Dynamic invariant: scoring profiles reject claim-dump keys."""

from __future__ import annotations

import sys
from pathlib import Path

# Allow `from _common import ...` when launched as py path/to/script.py
sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import ensure_kpi_on_path, fail_exit, pass_exit


def _minimal_profile() -> dict:
    return {
        "profile_schema_version": "1.0",
        "name": "cert_denylist_probe",
        "description": "Certification denylist probe profile (no claims).",
    }


def main() -> None:
    ensure_kpi_on_path()
    from kpi_modules.profiles import DENYLIST_KEYS, validate_profile_envelope

    # Clean profile must accept
    try:
        validate_profile_envelope(_minimal_profile())
    except ValueError as exc:
        fail_exit(f"clean profile rejected: {type(exc).__name__}")

    rejected = 0
    for key in sorted(DENYLIST_KEYS):
        # Top-level injection
        bad = _minimal_profile()
        bad[key] = []
        try:
            validate_profile_envelope(bad)
            fail_exit(f"denylist missed top-level key id={key}")
        except ValueError:
            rejected += 1

        # Nested under config
        bad2 = _minimal_profile()
        bad2["config"] = {key: []}
        try:
            validate_profile_envelope(bad2)
            fail_exit(f"denylist missed nested config key id={key}")
        except ValueError:
            rejected += 1

    pass_exit(
        f"profile denylist ok; clean_accept=true; injections_rejected={rejected}"
    )


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        fail_exit(f"invariant_profile_denylist error: {type(exc).__name__}")
