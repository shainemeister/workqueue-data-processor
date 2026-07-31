"""Dynamic invariant: score with privacy on masks patient and blanks DOB.

Never prints raw patient names or DOB values (row index + assertion only).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Allow `from _common import ...` when launched as py path/to/script.py
sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import ensure_kpi_on_path, fail_exit, pass_exit, repo_root

# Default prefix_token mask: LAST3+4digits,FIRST3+4digits
_MASK_RE = re.compile(r"^[A-Z]{3}\d{4},[A-Z]{3}\d{4}$")


def main() -> None:
    ensure_kpi_on_path()
    from kpi_modules.config import load_config, validate_config
    from kpi_modules.io_csv import read_csv_rows
    from kpi_modules.score_v1 import score_rows

    root = repo_root()
    fixture = root / "certification" / "fixtures" / "privacy_score_input.csv"
    if not fixture.is_file():
        fail_exit("privacy fixture missing")

    fieldnames, rows = read_csv_rows(fixture)
    if not rows:
        fail_exit("privacy fixture empty")

    # Snapshot raw PHI before scoring (for absence checks only; not printed).
    raw_patients = [str(r.get("patient", "") or "") for r in rows]
    raw_dobs = [str(r.get("dob", "") or "") for r in rows]

    cfg = validate_config(load_config())
    privacy = cfg.setdefault("privacy", {})
    privacy["enabled"] = True
    privacy.setdefault("patient", {})["mode"] = "prefix_token"
    privacy.setdefault("dob", {})["mode"] = "omit"

    _fields, out_rows, summary = score_rows(fieldnames, rows, cfg)
    pstats = summary.get("privacy") if isinstance(summary, dict) else None
    if not isinstance(pstats, dict):
        # score_rows may nest privacy under summary differently — read from apply path
        pstats = {}

    # score_rows returns summary with privacy key when present
    if "privacy" in (summary or {}):
        pstats = summary["privacy"]

    enabled = bool(pstats.get("enabled", True))
    if not enabled:
        fail_exit("privacy not enabled after score")

    mask_fail = 0
    dob_fail = 0
    raw_patient_leak = 0
    raw_dob_leak = 0

    for i, out in enumerate(out_rows):
        patient = str(out.get("patient", "") or "")
        dob = str(out.get("dob", "") or "")
        if not _MASK_RE.match(patient):
            mask_fail += 1
        if dob.strip():
            dob_fail += 1

        # Raw fixture PHI must not appear in any cell value
        row_text = " ".join(str(v) for v in out.values())
        if i < len(raw_patients) and raw_patients[i] and raw_patients[i] in row_text:
            raw_patient_leak += 1
        if i < len(raw_dobs) and raw_dobs[i] and raw_dobs[i] in row_text:
            raw_dob_leak += 1

    if mask_fail or dob_fail or raw_patient_leak or raw_dob_leak:
        fail_exit(
            f"privacy assertions failed "
            f"(mask_fail={mask_fail}; dob_fail={dob_fail}; "
            f"patient_leak={raw_patient_leak}; dob_leak={raw_dob_leak})"
        )

    n = len(out_rows)
    pass_exit(
        f"privacy ok; rows={n}; mask=prefix_token; dob_blank=true; no_raw_phi"
    )


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001 — top-level cert assert
        fail_exit(f"invariant_privacy_score error: {type(exc).__name__}")
