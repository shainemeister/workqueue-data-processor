"""Validate Priority Matrix V1 scores: integrity + optional golden fixture."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .config import METRIC_KEYS, load_config
from .io_csv import read_csv_rows
from .kpi_quantifiers import check_kpi_quantifier_integrity
from .score_v1 import score_rows


def _to_float(value: Any) -> float | None:
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    return float(text)


def _approx_equal(a: float | None, b: float | None, eps: float) -> bool:
    if a is None and b is None:
        return True
    if a is None or b is None:
        return False
    return abs(float(a) - float(b)) <= eps


def check_contrib_integrity(
    rows: list[dict[str, Any]],
    *,
    prefix: str = "v1_",
    score_column: str = "v1_priority_score",
    epsilon: float = 1e-5,
) -> list[dict[str, Any]]:
    """Return list of failures where score != sum(contrib)."""
    failures: list[dict[str, Any]] = []
    for i, row in enumerate(rows):
        contrib_sum = 0.0
        missing = False
        for key in METRIC_KEYS:
            c = _to_float(row.get(f"{prefix}contrib_{key}"))
            if c is None:
                missing = True
                break
            contrib_sum += c
        score = _to_float(row.get(score_column))
        if missing or score is None:
            failures.append(
                {
                    "RowIndex": i,
                    "Patient": row.get("patient"),
                    "Account": row.get("account"),
                    "Issue": "missing_score_or_contrib",
                    "Score": score,
                    "ContribSum": None if missing else contrib_sum,
                }
            )
            continue
        if abs(score - contrib_sum) > epsilon:
            failures.append(
                {
                    "RowIndex": i,
                    "Patient": row.get("patient"),
                    "Account": row.get("account"),
                    "Issue": "score_ne_sum_contrib",
                    "Score": score,
                    "ContribSum": contrib_sum,
                    "Delta": score - contrib_sum,
                }
            )
    return failures


def check_against_expected(
    scored_rows: list[dict[str, Any]],
    expected: dict[str, Any],
    *,
    epsilon: float | None = None,
) -> list[dict[str, Any]]:
    """Compare scored rows to golden expected JSON structure."""
    eps = float(expected.get("epsilon", 1e-5) if epsilon is None else epsilon)
    failures: list[dict[str, Any]] = []

    exp_mode = expected.get("queue_mode")
    if exp_mode is not None:
        actual_mode = None
        if scored_rows:
            actual_mode = scored_rows[0].get("v1_queue_mode")
        if str(actual_mode) != str(exp_mode):
            failures.append(
                {
                    "Issue": "queue_mode_mismatch",
                    "Expected": exp_mode,
                    "Actual": actual_mode,
                }
            )

    exp_weights = expected.get("weights")
    if isinstance(exp_weights, dict) and scored_rows:
        for key in METRIC_KEYS:
            exp_w = exp_weights.get(key)
            act_w = _to_float(scored_rows[0].get(f"v1_weight_{key}"))
            if exp_w is not None and not _approx_equal(float(exp_w), act_w, eps):
                failures.append(
                    {
                        "Issue": "weight_mismatch",
                        "Metric": key,
                        "Expected": exp_w,
                        "Actual": act_w,
                    }
                )

    exp_rows = list(expected.get("rows") or [])
    if len(exp_rows) != len(scored_rows):
        failures.append(
            {
                "Issue": "row_count_mismatch",
                "Expected": len(exp_rows),
                "Actual": len(scored_rows),
            }
        )
        return failures

    compare_keys = ["v1_priority_score"]
    for key in METRIC_KEYS:
        compare_keys.extend(
            [f"v1_raw_{key}", f"v1_norm_{key}", f"v1_contrib_{key}"]
        )

    for i, (exp, act) in enumerate(zip(exp_rows, scored_rows)):
        # Identity match helpers
        for id_key in ("patient", "account"):
            if id_key in exp and exp[id_key] is not None:
                if str(exp[id_key]) != str(act.get(id_key, "")):
                    failures.append(
                        {
                            "RowIndex": i,
                            "Issue": f"{id_key}_mismatch",
                            "Expected": exp[id_key],
                            "Actual": act.get(id_key),
                        }
                    )

        for col in compare_keys:
            if col not in exp:
                continue
            exp_v = exp.get(col)
            act_v = _to_float(act.get(col)) if col != "v1_queue_mode" else act.get(col)
            if col.startswith("v1_") and col != "v1_queue_mode":
                # Treat only None / blank string as missing — keep numeric 0.0
                if exp_v is None or (
                    isinstance(exp_v, str) and not str(exp_v).strip()
                ):
                    exp_f = None
                else:
                    exp_f = float(exp_v)
                act_f = (
                    act_v
                    if isinstance(act_v, float)
                    else _to_float(act_v)
                )
                if not _approx_equal(exp_f, act_f, eps):
                    failures.append(
                        {
                            "RowIndex": i,
                            "Patient": act.get("patient"),
                            "Issue": "value_mismatch",
                            "Column": col,
                            "Expected": exp_v,
                            "Actual": act.get(col),
                        }
                    )
    return failures


def validate_score(
    *,
    csv_path: str | Path,
    config_path: str | Path | None = None,
    expected_path: str | Path | None = None,
    epsilon: float = 1e-5,
    scored_csv_path: str | Path | None = None,
) -> dict[str, Any]:
    """
    Score a CSV (or use pre-scored file) and validate integrity / golden values.

    If *scored_csv_path* is set, that file is treated as already-scored output
    (skips recompute). Otherwise input is scored in memory.
    """
    cfg = load_config(config_path)
    prefix = str(cfg["output"].get("prefix", "v1_"))
    score_col = str(cfg["output"].get("score_column", "v1_priority_score"))

    if scored_csv_path:
        fieldnames, scored_rows = read_csv_rows(scored_csv_path)
        first = scored_rows[0] if scored_rows else {}
        summary = {
            "row_count": len(scored_rows),
            "as_of_date": first.get(f"{prefix}as_of_date") or None,
            "queue_mode": (
                first.get(f"{prefix}queue_mode")
                or first.get("v1_queue_mode")
                or None
            ),
            "source": "scored_csv",
        }
        # mode column name may be v1_queue_mode
        if scored_rows and summary["queue_mode"] is None:
            summary["queue_mode"] = scored_rows[0].get(score_col and "v1_queue_mode")
    else:
        fieldnames, rows = read_csv_rows(csv_path)
        fieldnames, scored_rows, summary = score_rows(fieldnames, rows, cfg)
        summary = dict(summary)
        summary["source"] = "recomputed"

    integrity = check_contrib_integrity(
        scored_rows,
        prefix=prefix,
        score_column=score_col,
        epsilon=epsilon,
    )

    summary_kpi = summary.get("kpi_totals") if isinstance(summary, dict) else None
    kpi_totals, kpi_failures = check_kpi_quantifier_integrity(
        scored_rows,
        epsilon=max(epsilon, 1e-4),
        expected_totals=summary_kpi if isinstance(summary_kpi, dict) else None,
    )

    golden: list[dict[str, Any]] = []
    expected_meta: dict[str, Any] | None = None
    if expected_path:
        ep = Path(expected_path)
        if not ep.is_file():
            raise FileNotFoundError(f"Expected fixture not found: {ep}")
        with ep.open("r", encoding="utf-8") as fh:
            expected_meta = json.load(fh)
        golden = check_against_expected(
            scored_rows,
            expected_meta,
            epsilon=float(expected_meta.get("epsilon", epsilon)),
        )
        # Optional golden KPI totals (numeric keys only)
        exp_kpi = expected_meta.get("kpi_totals")
        if isinstance(exp_kpi, dict):
            for col, exp in exp_kpi.items():
                if not isinstance(exp, (int, float)):
                    continue
                act = kpi_totals.get(col)
                if act is None or not isinstance(act, (int, float)):
                    # try summary path already folded into kpi_totals
                    if act is None:
                        golden.append(
                            {
                                "Issue": "kpi_total_missing",
                                "Column": col,
                                "Expected": exp,
                            }
                        )
                    continue
                tol = max(float(expected_meta.get("epsilon", epsilon)), 1e-3)
                if "pct" in str(col) or "share" in str(col):
                    tol = max(tol, 0.05)
                if abs(float(exp) - float(act)) > tol:
                    golden.append(
                        {
                            "Issue": "kpi_total_mismatch",
                            "Column": col,
                            "Expected": exp,
                            "Actual": act,
                        }
                    )

    failures = integrity + kpi_failures + golden
    ok = not failures

    # Sample top/bottom for human review when recomputed
    samples: list[dict[str, Any]] = []
    try:
        ranked = sorted(
            scored_rows,
            key=lambda r: _to_float(r.get(score_col)) or 0.0,
            reverse=True,
        )
        for r in ranked[:3] + ranked[-2:]:
            samples.append(
                {
                    "patient": r.get("patient"),
                    "account": r.get("account"),
                    "score": r.get(score_col),
                    "raw_ar_days": r.get(f"{prefix}raw_ar_days"),
                    "raw_out_ins_amt": r.get(f"{prefix}raw_out_ins_amt"),
                    "raw_appeal_urgency": r.get(f"{prefix}raw_appeal_urgency"),
                }
            )
    except Exception:
        samples = []

    return {
        "Success": ok,
        "Command": "validate-score",
        "InputPath": str(Path(csv_path).resolve()) if csv_path else None,
        "ConfigPath": str(Path(config_path).resolve()) if config_path else None,
        "ExpectedPath": str(Path(expected_path).resolve()) if expected_path else None,
        "ScoredCsvPath": str(Path(scored_csv_path).resolve()) if scored_csv_path else None,
        "RowCount": len(scored_rows),
        "QueueMode": summary.get("queue_mode"),
        "AsOfDate": summary.get("as_of_date"),
        "IntegrityFailureCount": len(integrity),
        "KpiFailureCount": len(kpi_failures),
        "GoldenFailureCount": len(golden),
        "FailureCount": len(failures),
        "Failures": failures[:50],  # cap noise
        "KpiTotals": kpi_totals,
        "SamplesHighLow": samples,
        "Message": (
            "Validation passed."
            if ok
            else f"Validation failed ({len(failures)} issue(s))."
        ),
    }
