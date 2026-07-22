"""Priority Matrix V1 scoring orchestration."""

from __future__ import annotations

from datetime import date
from pathlib import Path
from typing import Any

from .config import METRIC_KEYS, effective_weights, load_config
from .io_csv import read_csv_rows, write_csv_rows
from .kpi_quantifiers import apply_quantifiers_to_rows
from .metrics import compute_raw_metrics, detect_chaos_mode, resolve_as_of
from .normalize import normalize_all
from .summary_report import default_summary_path, write_summary_csv


def _fmt_num(value: float | None, digits: int = 6) -> str:
    if value is None:
        return ""
    # Prefer compact integers when whole
    if abs(value - round(value)) < 1e-9:
        return str(int(round(value)))
    return f"{value:.{digits}f}".rstrip("0").rstrip(".")


def score_rows(
    fieldnames: list[str],
    rows: list[dict[str, str]],
    cfg: dict[str, Any],
    *,
    as_of: date | None = None,
) -> tuple[list[str], list[dict[str, Any]], dict[str, Any]]:
    """
    Score in-memory rows and attach portfolio KPI quantifiers.

    Returns (output_fieldnames, output_rows, summary).

    Priority score (v1_*) and portfolio KPIs (kpi_q_*) are independent:
    - v1_* ranks work (0-1)
    - kpi_q_* sum across rows to dataset-level KPIs
    """
    if as_of is None:
        as_of = resolve_as_of(cfg)

    raw_list = [compute_raw_metrics(row, cfg, as_of) for row in rows]
    chaos_mode, chaos_stats = detect_chaos_mode(raw_list, cfg)
    weights = effective_weights(cfg, chaos_mode)
    ratios = normalize_all(raw_list, cfg)

    prefix = str(cfg["output"].get("prefix", "v1_"))
    score_col = str(cfg["output"].get("score_column", "v1_priority_score"))
    mode_col = str(cfg["output"].get("mode_column", "v1_queue_mode"))
    mode_label = "chaos" if chaos_mode else "healthy"

    audit_cols: list[str] = [
        f"{prefix}as_of_date",
        mode_col,
        f"{prefix}poi_name",
        f"{prefix}normalization",
    ]
    for key in METRIC_KEYS:
        audit_cols.append(f"{prefix}raw_{key}")
    for key in METRIC_KEYS:
        audit_cols.append(f"{prefix}norm_{key}")
    for key in METRIC_KEYS:
        audit_cols.append(f"{prefix}weight_{key}")
    for key in METRIC_KEYS:
        audit_cols.append(f"{prefix}contrib_{key}")
    audit_cols.append(score_col)

    poi_name = str(cfg.get("point_of_interest", {}).get("name", "default"))
    norm_method = str(cfg.get("normalization", "minmax"))

    out_rows: list[dict[str, Any]] = []
    scores: list[float] = []

    for i, src in enumerate(rows):
        raw = raw_list[i]
        norm = ratios[i]
        out = dict(src)
        out[f"{prefix}as_of_date"] = as_of.isoformat()
        out[mode_col] = mode_label
        out[f"{prefix}poi_name"] = poi_name
        out[f"{prefix}normalization"] = norm_method

        score = 0.0
        for key in METRIC_KEYS:
            w = weights[key]
            nval = float(norm[key])
            contrib = w * nval
            score += contrib
            out[f"{prefix}raw_{key}"] = _fmt_num(raw.get(key))
            out[f"{prefix}norm_{key}"] = _fmt_num(nval)
            out[f"{prefix}weight_{key}"] = _fmt_num(w)
            out[f"{prefix}contrib_{key}"] = _fmt_num(contrib)

        if score < 0.0:
            score = 0.0
        elif score > 1.0:
            score = 1.0
        out[score_col] = _fmt_num(score)
        scores.append(score)
        out_rows.append(out)

    # Portfolio KPI quantifiers (sum across rows = dataset KPI; not priority)
    kpi_cols, kpi_totals = apply_quantifiers_to_rows(out_rows, raw_list, cfg)

    out_fields = list(fieldnames)
    for col in audit_cols + kpi_cols:
        if col not in out_fields:
            out_fields.append(col)

    summary = {
        "row_count": len(out_rows),
        "column_count": len(out_fields),
        "as_of_date": as_of.isoformat(),
        "queue_mode": mode_label,
        "chaos": chaos_stats,
        "weights": {k: round(weights[k], 6) for k in METRIC_KEYS},
        "poi_name": poi_name,
        "normalization": norm_method,
        "score_min": round(min(scores), 6) if scores else None,
        "score_max": round(max(scores), 6) if scores else None,
        "score_mean": round(sum(scores) / len(scores), 6) if scores else None,
        "score_column": score_col,
        "kpi_totals": kpi_totals,
        "kpi_columns": kpi_cols,
    }
    return out_fields, out_rows, summary


def score_csv(
    csv_path: str | Path,
    output_path: str | Path,
    *,
    config_path: str | Path | None = None,
    dry_run: bool = False,
    summary_path: str | Path | None = None,
    write_summary: bool = True,
) -> dict[str, Any]:
    """
    Score a data CSV and write an enriched CSV.

    Also writes a vertical summary CSV (metrics as rows) unless write_summary is False.

    Returns a result dict suitable for CLI JSON output.
    """
    cfg = load_config(config_path)
    fieldnames, rows = read_csv_rows(csv_path)
    out_fields, out_rows, summary = score_rows(fieldnames, rows, cfg)

    out_resolved = Path(output_path).resolve()
    sum_path = (
        Path(summary_path).resolve()
        if summary_path
        else default_summary_path(out_resolved)
    )

    result: dict[str, Any] = {
        "Success": True,
        "Command": "score",
        "InputPath": str(Path(csv_path).resolve()),
        "OutputPath": str(out_resolved),
        "SummaryPath": str(sum_path) if write_summary else None,
        "RowCount": summary["row_count"],
        "ColumnCount": summary["column_count"],
        "DryRun": dry_run,
        "QueueMode": summary["queue_mode"],
        "AsOfDate": summary["as_of_date"],
        "ScoreMin": summary["score_min"],
        "ScoreMax": summary["score_max"],
        "ScoreMean": summary["score_mean"],
        "ScoreColumn": summary["score_column"],
        "PoiName": summary["poi_name"],
        "Normalization": summary["normalization"],
        "Weights": summary["weights"],
        "Chaos": summary["chaos"],
        "KpiTotals": summary.get("kpi_totals") or {},
        "KpiColumns": summary.get("kpi_columns") or [],
        "Message": "Dry-run only; no file written." if dry_run else "Score complete.",
    }

    if not dry_run:
        write_csv_rows(output_path, out_fields, out_rows)
        if write_summary:
            write_summary_csv(
                sum_path,
                summary,
                input_path=csv_path,
                output_path=out_resolved,
                config_path=config_path,
            )
            result["Message"] = "Score complete (detail + summary)."
        else:
            result["Message"] = "Score complete."

    return result
