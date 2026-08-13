"""Priority Matrix V1 scoring orchestration."""

from __future__ import annotations

from copy import deepcopy
from datetime import date
from pathlib import Path
from typing import Any

import sys

from .column_map import (
    MappingGuideAbort,
    apply_mapping_to_config,
    guide_mapping,
    load_mapping_profile,
    mapping_has_problems,
    offer_save_mapping_profile,
    problems_summary,
)
from .completeness import (
    evaluate_rank_completeness,
    format_strict_failure_message,
    strict_mode_allows,
)
from .config import METRIC_KEYS, effective_weights, load_config, validate_config
from .io_csv import read_csv_rows, resolve_unique_path, write_csv_rows
from .output_sort import (
    apply_output_sort,
    resolve_sort_spec,
    sort_applied_payload,
)
from .kpi_quantifiers import apply_quantifiers_to_rows
from .metrics import compute_raw_metrics, detect_chaos_mode, resolve_as_of
from .normalize import normalize_all
from .privacy import apply_privacy_to_rows
from .summary_report import default_summary_path, write_summary_csv


def _fmt_num(value: float | None, digits: int = 6) -> str:
    if value is None:
        return ""
    # Prefer compact integers when whole
    if abs(value - round(value)) < 1e-9:
        return str(int(round(value)))
    return f"{value:.{digits}f}".rstrip("0").rstrip(".")


def _metric_value_coverage(
    raw_list: list[dict[str, float | None]],
    active: list[str],
    *,
    low_threshold: float = 0.5,
) -> dict[str, Any]:
    """
    Fraction of rows with non-null raw values per active metric.

    ActiveMetrics means the role column was resolved; coverage means the
    metric actually produced a numeric raw for the row (dates/numbers parsed).
    """
    n = len(raw_list)
    coverage: dict[str, float] = {}
    low: list[str] = []
    for key in active:
        if n <= 0:
            coverage[key] = 0.0
            low.append(key)
            continue
        present = sum(
            1 for raw in raw_list if raw.get(key) is not None
        )
        ratio = present / n
        coverage[key] = round(ratio, 6)
        if ratio < low_threshold:
            low.append(key)
    return {
        "coverage": coverage,
        "low_coverage_metrics": low,
        "low_coverage_threshold": low_threshold,
        "row_count": n,
    }


def score_rows(
    fieldnames: list[str],
    rows: list[dict[str, str]],
    cfg: dict[str, Any],
    *,
    as_of: date | None = None,
    mapping_report: dict[str, Any] | None = None,
) -> tuple[list[str], list[dict[str, Any]], dict[str, Any]]:
    """
    Score in-memory rows and attach portfolio KPI quantifiers.

    Returns (output_fieldnames, output_rows, summary).

    Priority score (v1_*) and portfolio KPIs (kpi_q_*) are independent:
    - v1_* ranks work (0-1)
    - kpi_q_* sum across rows to dataset-level KPIs

    mapping_report: optional result from apply_mapping_to_config (active/skipped
    metrics and resolved roles). When omitted, all METRIC_KEYS stay active.
    """
    if as_of is None:
        as_of = resolve_as_of(cfg)

    if mapping_report is not None:
        active = list(mapping_report.get("active_metrics") or [])
        skipped = dict(mapping_report.get("skipped_metrics") or {})
    else:
        active = list(METRIC_KEYS)
        skipped = {}

    raw_list = [compute_raw_metrics(row, cfg, as_of) for row in rows]
    coverage_info = _metric_value_coverage(raw_list, active)
    chaos_mode, chaos_stats = detect_chaos_mode(raw_list, cfg)
    weights = effective_weights(cfg, chaos_mode, active_metrics=active)
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

    # PHI masking on output only (after metrics / KPI Q; input CSV unchanged)
    privacy_stats = apply_privacy_to_rows(out_rows, cfg)

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
        "privacy": privacy_stats,
        "active_metrics": list(active),
        "skipped_metrics": skipped,
        "metric_value_coverage": coverage_info["coverage"],
        "low_coverage_metrics": coverage_info["low_coverage_metrics"],
        "low_coverage_threshold": coverage_info["low_coverage_threshold"],
        "field_roles": (
            dict(mapping_report.get("resolved") or {})
            if mapping_report is not None
            else {}
        ),
        "missing_roles": (
            list(mapping_report.get("missing_roles") or [])
            if mapping_report is not None
            else []
        ),
        "ambiguous_roles": (
            dict(mapping_report.get("ambiguous") or {})
            if mapping_report is not None
            else {}
        ),
        "low_confidence_roles": (
            list(mapping_report.get("low_confidence_roles") or [])
            if mapping_report is not None
            else []
        ),
        "mapping_sources": (
            dict(mapping_report.get("sources") or {})
            if mapping_report is not None
            else {}
        ),
        "role_confidence": (
            dict(mapping_report.get("role_confidence") or {})
            if mapping_report is not None
            else {}
        ),
        "type_checks": (
            dict(mapping_report.get("type_checks") or {})
            if mapping_report is not None
            else {}
        ),
    }
    return out_fields, out_rows, summary


def score_csv(
    csv_path: str | Path,
    output_path: str | Path,
    *,
    config_path: str | Path | None = None,
    config: dict[str, Any] | None = None,
    dry_run: bool = False,
    summary_path: str | Path | None = None,
    write_summary: bool = True,
    privacy_enabled: bool | None = None,
    mapping_path: str | Path | None = None,
    mapping_roles: dict[str, str] | None = None,
    interactive_mapping: bool = False,
    strict: str | None = None,
    force: bool = False,
    sort_spec: str | None = None,
    sort_preset: str | None = None,
) -> dict[str, Any]:
    """
    Score a data CSV and write an enriched CSV.

    Also writes a vertical summary CSV (metrics as rows) unless write_summary is False.

    config: optional config dict (e.g. from a scoring profile). Validated via
    validate_config. When provided, *config_path* is ignored for loading. When
    omitted, config is loaded via load_config(config_path).

    privacy_enabled: if not None, overrides config privacy.enabled (CLI --privacy /
    --no-privacy). None keeps the JSON config value.

    mapping_path: optional JSON mapping profile (role → CSV headers).
    mapping_roles: optional in-memory role map (used when mapping_path is None).
    Headers are always inspected (case/space tolerant + aliases); explicit roles
    override auto-detect for listed roles.

    interactive_mapping: when True and mapping problems exist, run guided
    resolution on a TTY; on non-TTY fail clearly instead of hanging.

    strict: None (default), \"roles\", or \"full\". When set, fail without writing
    files if rank completeness does not meet that tier (see completeness module).

    sort_spec / sort_preset: optional post-score detail-row order (Cluster 3.2).
    Default (both omitted) keeps input order. Mutually exclusive.

    force: when False (default), if the output path already exists, write to a
    unique sibling path with a numerical suffix (``name_1.ext``). When True,
    overwrite the exact output path. Explicit summary paths are resolved the same
    way; default summary paths follow the resolved scored path stem.

    Returns a result dict suitable for CLI JSON output.
    """
    if config is not None:
        if not isinstance(config, dict):
            raise ValueError("config must be a dict when provided")
        base_cfg = validate_config(deepcopy(config))
    else:
        base_cfg = load_config(config_path)

    cfg = deepcopy(base_cfg)
    if privacy_enabled is not None:
        privacy = cfg.setdefault("privacy", {})
        if not isinstance(privacy, dict):
            privacy = {}
            cfg["privacy"] = privacy
        privacy["enabled"] = bool(privacy_enabled)

    fieldnames, rows = read_csv_rows(csv_path)
    input_resolved = Path(csv_path).resolve()

    profile_roles: dict[str, str] | None = None
    if mapping_path is not None:
        profile_roles = load_mapping_profile(mapping_path)
    elif mapping_roles is not None:
        profile_roles = dict(mapping_roles)

    # Defer the zero-metrics hard-fail until after optional guided recovery.
    cfg, mapping_report = apply_mapping_to_config(
        cfg,
        fieldnames,
        profile_roles=profile_roles,
        require_active_metric=False,
        sample_rows=rows,
    )

    saved_mapping_path: str | None = (
        str(Path(mapping_path).resolve()) if mapping_path else None
    )
    guided = False

    if interactive_mapping and mapping_has_problems(mapping_report):
        tty = bool(sys.stdin.isatty() and sys.stdout.isatty())
        if not tty:
            raise ValueError(
                "Interactive mapping required but no TTY available. "
                "Problems: "
                + problems_summary(mapping_report)
                + ". Provide a --mapping profile or run from an interactive console."
            )
        try:
            guided_roles = guide_mapping(
                fieldnames,
                mapping_report,
                sample_rows=rows,
                existing_roles=profile_roles,
            )
        except MappingGuideAbort as exc:
            raise ValueError(str(exc)) from exc

        # Re-apply guided roles on a fresh copy of the resolved base config
        # (preserves scoring-profile / POI overlays; do not reload package default).
        cfg = deepcopy(base_cfg)
        if privacy_enabled is not None:
            privacy = cfg.setdefault("privacy", {})
            if not isinstance(privacy, dict):
                privacy = {}
                cfg["privacy"] = privacy
            privacy["enabled"] = bool(privacy_enabled)

        profile_roles = guided_roles
        cfg, mapping_report = apply_mapping_to_config(
            cfg,
            fieldnames,
            profile_roles=profile_roles,
            require_active_metric=False,
            sample_rows=rows,
        )
        guided = True
        suggest = input_resolved.with_name(
            f"{input_resolved.stem}_mapping.json"
        )
        written = offer_save_mapping_profile(
            guided_roles,
            suggest_path=suggest,
        )
        if written is not None:
            saved_mapping_path = str(written)

    if not mapping_report.get("active_metrics"):
        missing = ", ".join(mapping_report.get("missing_roles") or []) or (
            "(none listed)"
        )
        raise ValueError(
            "No priority metrics can run: required columns missing "
            "for all metrics. "
            f"Unresolved roles: {missing}. "
            "Provide correctly named headers, a --mapping profile, "
            "or re-run with --interactive-mapping on a TTY."
        )

    sort_text, preset_name, sort_pairs = resolve_sort_spec(
        sort_spec=sort_spec,
        sort_preset=sort_preset,
    )

    out_fields, out_rows, summary = score_rows(
        fieldnames,
        rows,
        cfg,
        mapping_report=mapping_report,
    )
    if sort_pairs:
        out_rows = apply_output_sort(out_rows, sort_pairs, out_fields)

    completeness = evaluate_rank_completeness(
        active_metrics=summary.get("active_metrics"),
        skipped_metrics=summary.get("skipped_metrics"),
        missing_roles=summary.get("missing_roles"),
        ambiguous_roles=summary.get("ambiguous_roles"),
        low_coverage_metrics=summary.get("low_coverage_metrics"),
    )
    summary["rank_completeness"] = completeness["rank_completeness"]
    summary["incomplete_reasons"] = list(
        completeness["incomplete_reasons"]
    )

    requested_out = Path(output_path)
    # Unique path unless force (plan dry-run targets the same way so JSON matches)
    out_write, out_requested, out_adjusted = resolve_unique_path(
        requested_out, force=bool(force)
    )
    out_resolved = out_write.resolve()
    out_requested_resolved = out_requested.resolve()

    summary_explicit = summary_path is not None
    if write_summary:
        if summary_explicit:
            sum_write, sum_requested, sum_adjusted = resolve_unique_path(
                Path(summary_path), force=bool(force)
            )
            sum_path = sum_write.resolve()
            sum_requested_resolved = sum_requested.resolve()
        else:
            # Derive summary from resolved scored path so pair stays aligned
            sum_path = default_summary_path(out_resolved)
            sum_requested_resolved = default_summary_path(out_requested_resolved)
            sum_adjusted = out_adjusted
    else:
        sum_path = None
        sum_requested_resolved = None
        sum_adjusted = False

    strict_mode = None
    if strict is not None and str(strict).strip():
        strict_mode = str(strict).strip().lower()

    strict_ok = strict_mode_allows(strict_mode, completeness)
    success = True
    message = (
        "Dry-run only; no file written." if dry_run else "Score complete."
    )

    if not strict_ok:
        success = False
        message = format_strict_failure_message(
            strict_mode or "full", completeness
        )

    result: dict[str, Any] = {
        "Success": success,
        "Command": "score",
        "InputPath": str(input_resolved),
        "OutputPath": str(out_resolved),
        "RequestedOutputPath": str(out_requested_resolved),
        "OutputPathAdjusted": bool(out_adjusted),
        "SummaryPath": str(sum_path) if write_summary else None,
        "RequestedSummaryPath": (
            str(sum_requested_resolved) if write_summary else None
        ),
        "SummaryPathAdjusted": bool(sum_adjusted) if write_summary else False,
        "Force": bool(force),
        "SortSpec": sort_text,
        "SortPreset": preset_name,
        "SortApplied": sort_applied_payload(sort_pairs),
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
        "ActiveMetrics": summary.get("active_metrics") or [],
        "SkippedMetrics": summary.get("skipped_metrics") or {},
        "MetricValueCoverage": summary.get("metric_value_coverage") or {},
        "LowCoverageMetrics": summary.get("low_coverage_metrics") or [],
        "LowCoverageThreshold": summary.get("low_coverage_threshold"),
        "RankCompleteness": completeness["rank_completeness"],
        "IncompleteReasons": list(completeness["incomplete_reasons"]),
        "StrictMode": strict_mode,
        "StrictPassed": (
            None if strict_mode is None else bool(strict_ok)
        ),
        "FieldRoles": summary.get("field_roles") or {},
        "MissingRoles": summary.get("missing_roles") or [],
        "AmbiguousRoles": summary.get("ambiguous_roles") or {},
        "LowConfidenceRoles": summary.get("low_confidence_roles") or [],
        "MappingSources": summary.get("mapping_sources") or {},
        "RoleConfidence": summary.get("role_confidence") or {},
        "TypeChecks": summary.get("type_checks") or {},
        "MappingPath": saved_mapping_path,
        "InteractiveMapping": bool(interactive_mapping),
        "GuidedMappingApplied": guided,
        "PrivacyEnabled": bool((summary.get("privacy") or {}).get("enabled")),
        "PrivacyPatientMode": (summary.get("privacy") or {}).get(
            "patient_mode"
        ),
        "PrivacyDobMode": (summary.get("privacy") or {}).get("dob_mode"),
        "PrivacyPatientField": (summary.get("privacy") or {}).get(
            "patient_field"
        ),
        "PrivacyDobField": (summary.get("privacy") or {}).get("dob_field"),
        "PrivacyPatientSource": (summary.get("privacy") or {}).get(
            "patient_source"
        ),
        "PrivacyDobSource": (summary.get("privacy") or {}).get("dob_source"),
        "PrivacyTokenDigits": (summary.get("privacy") or {}).get(
            "token_digits"
        ),
        "PrivacyUniquePatients": (summary.get("privacy") or {}).get(
            "unique_patients"
        ),
        "PrivacyCliOverride": (
            None
            if privacy_enabled is None
            else bool(privacy_enabled)
        ),
        "Message": message,
    }

    # Fail-before-write when strict mode rejects partial ranks.
    if not dry_run and success:
        write_csv_rows(out_resolved, out_fields, out_rows)
        if write_summary and sum_path is not None:
            write_summary_csv(
                sum_path,
                summary,
                input_path=csv_path,
                output_path=out_resolved,
                config_path=config_path,
            )
            if out_adjusted:
                result["Message"] = (
                    "Score complete (detail + summary; avoided overwrite of "
                    f"{out_requested_resolved})."
                )
            else:
                result["Message"] = "Score complete (detail + summary)."
        else:
            if out_adjusted:
                result["Message"] = (
                    "Score complete (avoided overwrite of "
                    f"{out_requested_resolved})."
                )
            else:
                result["Message"] = "Score complete."
    elif dry_run and success:
        if out_adjusted:
            result["Message"] = (
                "Dry-run only; no file written "
                f"(would write to {out_resolved}; avoided overwrite of "
                f"{out_requested_resolved})."
            )
        else:
            result["Message"] = "Dry-run only; no file written."
    elif not success:
        result["OutputPath"] = None
        result["SummaryPath"] = None
        result["RequestedSummaryPath"] = None

    return result
