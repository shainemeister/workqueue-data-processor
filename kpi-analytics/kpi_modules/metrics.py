"""Raw Priority Matrix V1 metric calculations (stdlib only)."""

from __future__ import annotations

from datetime import date, datetime
from typing import Any


def parse_date(value: str | None, formats: list[str]) -> date | None:
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    for fmt in formats:
        try:
            return datetime.strptime(text, fmt).date()
        except ValueError:
            continue
    return None


def parse_float(value: str | None) -> float | None:
    if value is None:
        return None
    text = str(value).strip().replace(",", "")
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def parse_int(value: str | None) -> int | None:
    f = parse_float(value)
    if f is None:
        return None
    return int(f)


def resolve_as_of(cfg: dict[str, Any]) -> date:
    raw = cfg.get("as_of_date")
    if raw is None or str(raw).strip() == "":
        return date.today()
    parsed = parse_date(str(raw), list(cfg.get("date_formats") or []))
    if parsed is None:
        raise ValueError(f"Invalid as_of_date in config: {raw!r}")
    return parsed


def compute_raw_metrics(
    row: dict[str, str],
    cfg: dict[str, Any],
    as_of: date,
) -> dict[str, float | None]:
    """Compute V1 raw metrics for one data row."""
    fields = cfg["fields"]
    formats = list(cfg["date_formats"])
    target = float(cfg["ar_day_target"])

    svc = parse_date(row.get(fields["service_date"]), formats)
    ar_days: float | None = None
    if svc is not None:
        ar_days = float((as_of - svc).days)

    ar_disparity: float | None = None
    if ar_days is not None:
        ar_disparity = ar_days - target

    out_ins = parse_float(row.get(fields["out_ins_amt"]))
    billed = parse_float(row.get(fields["billed_amount"]))
    appeal = parse_float(row.get(fields["days_until_appeal_deadline"]))
    wq_age = parse_float(row.get(fields["days_on_wq_tab"]))

    return {
        "ar_days": ar_days,
        "ar_disparity": ar_disparity,
        "out_ins_amt": out_ins,
        "billed_amount": billed,
        "appeal_urgency": appeal,
        "wq_age": wq_age,
    }


def detect_chaos_mode(
    raw_rows: list[dict[str, float | None]],
    cfg: dict[str, Any],
) -> tuple[bool, dict[str, Any]]:
    """Queue-level healthy vs chaos flag plus diagnostic stats."""
    chaos_cfg = cfg.get("chaos") or {}
    if not chaos_cfg.get("enabled", True):
        return False, {"enabled": False, "reasons": []}

    ar_values = [
        float(r["ar_days"])
        for r in raw_rows
        if r.get("ar_days") is not None
    ]
    n = len(ar_values)
    stats: dict[str, Any] = {
        "enabled": True,
        "row_count_with_ar_days": n,
        "reasons": [],
    }
    if n == 0:
        stats["mean_ar_days"] = None
        return False, stats

    mean_ar = sum(ar_values) / n
    target = float(cfg["ar_day_target"])
    share_60 = sum(1 for v in ar_values if v >= 60) / n
    share_90 = sum(1 for v in ar_values if v >= 90) / n
    share_120 = sum(1 for v in ar_values if v >= 120) / n

    stats.update(
        {
            "mean_ar_days": round(mean_ar, 4),
            "ar_day_target": target,
            "share_ar_ge_60": round(share_60, 4),
            "share_ar_ge_90": round(share_90, 4),
            "share_ar_ge_120": round(share_120, 4),
        }
    )

    reasons: list[str] = []
    factor = float(chaos_cfg.get("mean_ar_days_factor", 1.5))
    if mean_ar > target * factor:
        reasons.append(
            f"mean_ar_days {mean_ar:.2f} > target*{factor} ({target * factor:.2f})"
        )
    thr60 = float(chaos_cfg.get("share_ar_ge_60", 0.40))
    thr90 = float(chaos_cfg.get("share_ar_ge_90", 0.25))
    thr120 = float(chaos_cfg.get("share_ar_ge_120", 0.15))
    if share_60 >= thr60:
        reasons.append(f"share_ar_ge_60 {share_60:.2%} >= {thr60:.2%}")
    if share_90 >= thr90:
        reasons.append(f"share_ar_ge_90 {share_90:.2%} >= {thr90:.2%}")
    if share_120 >= thr120:
        reasons.append(f"share_ar_ge_120 {share_120:.2%} >= {thr120:.2%}")

    stats["reasons"] = reasons
    return (len(reasons) > 0), stats
