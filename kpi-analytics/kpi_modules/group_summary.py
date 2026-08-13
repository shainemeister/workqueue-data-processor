#requires Python 3.13 stdlib only
"""Post-score group summary CSV (Cluster 3.1 reporting). No V1 / kpi_q math."""

from __future__ import annotations

from pathlib import Path
from typing import Any

BLANK = "(blank)"

GROUP_PRESETS: dict[str, list[str]] = {
    "payer_category": ["payer", "code_category"],
    "payer": ["payer"],
    "category": ["code_category"],
    "location": ["location"],
}

AGG_FIELDS: tuple[str, ...] = (
    "claim_count",
    "sum_out_ins_amt",
    "sum_billed_amount",
    "sum_kpi_q_share_total_ar_pct",
    "max_v1_priority_score",
    "min_days_until_appeal_deadline",
    "max_v1_raw_claim_age_days",
    "max_denial_count",
    "max_v1_raw_days_since_last_worked",
)


def default_groups_path(scored_output_path: str | Path) -> Path:
    """Sibling ``<stem>_groups.csv`` next to the scored detail file."""
    path = Path(scored_output_path)
    return path.with_name(f"{path.stem}_groups{path.suffix}")


def parse_group_by(spec: str) -> list[str]:
    """Parse comma-separated group column names."""
    text = (spec or "").strip()
    if not text:
        raise ValueError("group-by spec is empty")
    keys: list[str] = []
    for raw in text.split(","):
        name = raw.strip()
        if not name:
            raise ValueError("group-by spec has an empty column name")
        if name in keys:
            raise ValueError(f"duplicate group-by column: {name}")
        keys.append(name)
    return keys


def resolve_group_by(
    *,
    group_by: str | None = None,
    group_preset: str | None = None,
) -> tuple[list[str], str | None]:
    """Resolve CLI group inputs. Empty inputs mean do not write a groups file."""
    spec_raw = (group_by or "").strip() or None
    preset_raw = (group_preset or "").strip() or None
    if spec_raw and preset_raw:
        raise ValueError("--group-by and --group-preset are mutually exclusive")
    if preset_raw:
        key = preset_raw.lower()
        if key not in GROUP_PRESETS:
            known = ", ".join(sorted(GROUP_PRESETS))
            raise ValueError(
                f"unknown group preset {preset_raw!r}; expected one of: {known}"
            )
        return list(GROUP_PRESETS[key]), key
    if spec_raw:
        return parse_group_by(spec_raw), None
    return [], None


def _parse_float(value: Any) -> float | None:
    text = "" if value is None else str(value).strip()
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def _cell_label(value: Any) -> str:
    text = "" if value is None else str(value).strip()
    if not text:
        return BLANK
    return text


def build_group_rows(
    rows: list[dict[str, Any]],
    keys: list[str],
    fieldnames: list[str],
) -> tuple[list[str], list[dict[str, Any]]]:
    """Aggregate scored detail rows. Groups sorted by sum AR, then count, then key."""
    if not keys:
        return [], []
    missing = [name for name in keys if name not in fieldnames]
    if missing:
        raise ValueError(
            "group-by column(s) not in scored output: " + ", ".join(missing)
        )

    buckets: dict[tuple[str, ...], dict[str, Any]] = {}
    for row in rows:
        labels = tuple(_cell_label(row.get(name)) for name in keys)
        bucket = buckets.get(labels)
        if bucket is None:
            bucket = {
                "claim_count": 0,
                "sum_out_ins_amt": 0.0,
                "sum_billed_amount": 0.0,
                "sum_kpi_q_share_total_ar_pct": 0.0,
                "max_v1_priority_score": None,
                "min_days_until_appeal_deadline": None,
                "max_v1_raw_claim_age_days": None,
                "max_denial_count": None,
                "max_v1_raw_days_since_last_worked": None,
            }
            buckets[labels] = bucket
        bucket["claim_count"] += 1
        money = _parse_float(row.get("out_ins_amt"))
        if money is not None:
            bucket["sum_out_ins_amt"] += money
        billed = _parse_float(row.get("billed_amount"))
        if billed is not None:
            bucket["sum_billed_amount"] += billed
        share = _parse_float(row.get("kpi_q_share_total_ar_pct"))
        if share is not None:
            bucket["sum_kpi_q_share_total_ar_pct"] += share
        pri = _parse_float(row.get("v1_priority_score"))
        if pri is not None:
            cur = bucket["max_v1_priority_score"]
            if cur is None or pri > cur:
                bucket["max_v1_priority_score"] = pri
        appeal = _parse_float(row.get("days_until_appeal_deadline"))
        if appeal is not None:
            cur = bucket["min_days_until_appeal_deadline"]
            if cur is None or appeal < cur:
                bucket["min_days_until_appeal_deadline"] = appeal
        age = _parse_float(row.get("v1_raw_claim_age_days"))
        if age is not None:
            cur = bucket["max_v1_raw_claim_age_days"]
            if cur is None or age > cur:
                bucket["max_v1_raw_claim_age_days"] = age
        denials = _parse_float(row.get("denial_count"))
        if denials is not None:
            cur = bucket["max_denial_count"]
            if cur is None or denials > cur:
                bucket["max_denial_count"] = denials
        stall = _parse_float(row.get("v1_raw_days_since_last_worked"))
        if stall is not None:
            cur = bucket["max_v1_raw_days_since_last_worked"]
            if cur is None or stall > cur:
                bucket["max_v1_raw_days_since_last_worked"] = stall

    out_fields = ["group_key", *keys, *AGG_FIELDS]
    out_rows: list[dict[str, Any]] = []
    for labels, bucket in buckets.items():
        row: dict[str, Any] = {
            "group_key": " | ".join(labels),
            "claim_count": bucket["claim_count"],
            "sum_out_ins_amt": bucket["sum_out_ins_amt"],
            "sum_billed_amount": bucket["sum_billed_amount"],
            "sum_kpi_q_share_total_ar_pct": bucket["sum_kpi_q_share_total_ar_pct"],
            "max_v1_priority_score": bucket["max_v1_priority_score"],
            "min_days_until_appeal_deadline": bucket[
                "min_days_until_appeal_deadline"
            ],
            "max_v1_raw_claim_age_days": bucket["max_v1_raw_claim_age_days"],
            "max_denial_count": bucket["max_denial_count"],
            "max_v1_raw_days_since_last_worked": bucket[
                "max_v1_raw_days_since_last_worked"
            ],
        }
        for name, label in zip(keys, labels):
            row[name] = label
        out_rows.append(row)

    out_rows.sort(
        key=lambda item: (
            -float(item["sum_out_ins_amt"]),
            -int(item["claim_count"]),
            str(item["group_key"]),
        )
    )
    return out_fields, out_rows
