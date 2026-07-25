"""Raw Priority Matrix metric calculations (stdlib only)."""

from __future__ import annotations

from datetime import date, datetime
from typing import Any


def parse_date(value: str | None, formats: list[str]) -> date | None:
    """Parse a date string with the first matching format, or return None."""
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
    """Parse a float (commas stripped), or return None if empty/invalid."""
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
    """Parse an integer via parse_float, or return None."""
    f = parse_float(value)
    if f is None:
        return None
    return int(f)


def resolve_as_of(cfg: dict[str, Any]) -> date:
    """Return config as_of_date or today when unset/blank."""
    raw = cfg.get("as_of_date")
    if raw is None or not str(raw).strip():
        return date.today()
    parsed = parse_date(str(raw), list(cfg.get("date_formats") or []))
    if parsed is None:
        raise ValueError(f"Invalid as_of_date in config: {raw!r}")
    return parsed


def _field(fields: dict[str, Any], role: str) -> str:
    """Return configured column name for a role, defaulting to the role key."""
    val = fields.get(role)
    if val is None or not str(val).strip():
        return role
    return str(val)


def compute_raw_metrics(
    row: dict[str, str],
    cfg: dict[str, Any],
    as_of: date,
) -> dict[str, float | None]:
    """Compute priority raw metrics for one data row (metric contract 2.0)."""
    fields = cfg["fields"]
    formats = list(cfg["date_formats"])
    target = float(cfg["claim_age_target"])

    svc = parse_date(row.get(_field(fields, "service_date")), formats)
    claim_age_days: float | None = None
    if svc is not None:
        claim_age_days = float((as_of - svc).days)

    claim_age_disparity: float | None = None
    if claim_age_days is not None:
        claim_age_disparity = claim_age_days - target

    out_ins = parse_float(row.get(_field(fields, "out_ins_amt")))
    billed = parse_float(row.get(_field(fields, "billed_amount")))
    appeal = parse_float(
        row.get(_field(fields, "days_until_appeal_deadline"))
    )
    wq_age = parse_float(row.get(_field(fields, "days_on_wq_tab")))

    # Balance-Weighted Days Outstanding (never labeled AR Days)
    bwdo: float | None = None
    if (
        claim_age_days is not None
        and out_ins is not None
        and billed is not None
        and billed > 0
    ):
        bwdo = (out_ins / billed) * claim_age_days

    denial_count = parse_float(row.get(_field(fields, "denial_count")))

    last_worked = parse_date(
        row.get(_field(fields, "last_worked_date")), formats
    )
    days_since_last_worked: float | None = None
    if last_worked is not None:
        days_since_last_worked = float((as_of - last_worked).days)

    replacement = parse_float(
        row.get(_field(fields, "days_until_replacement_deadline"))
    )
    # Dual-deadline urgency: fewer days remaining = higher priority after invert
    dual_deadline: float | None = None
    if appeal is not None and replacement is not None:
        dual_deadline = float(min(appeal, replacement))
    elif appeal is not None:
        dual_deadline = float(appeal)
    elif replacement is not None:
        dual_deadline = float(replacement)

    return {
        "claim_age_days": claim_age_days,
        "claim_age_disparity": claim_age_disparity,
        "out_ins_amt": out_ins,
        "billed_amount": billed,
        "appeal_urgency": appeal,
        "wq_age": wq_age,
        "balance_weighted_days_outstanding": bwdo,
        "denial_count": denial_count,
        "days_since_last_worked": days_since_last_worked,
        "dual_deadline_urgency": dual_deadline,
    }


def detect_chaos_mode(
    raw_rows: list[dict[str, float | None]],
    cfg: dict[str, Any],
) -> tuple[bool, dict[str, Any]]:
    """Queue-level healthy vs chaos flag plus diagnostic stats."""
    chaos_cfg = cfg.get("chaos") or {}
    if not chaos_cfg.get("enabled", True):
        return False, {"enabled": False, "reasons": []}

    age_values = [
        float(r["claim_age_days"])
        for r in raw_rows
        if r.get("claim_age_days") is not None
    ]
    n = len(age_values)
    stats: dict[str, Any] = {
        "enabled": True,
        "row_count_with_claim_age_days": n,
        "reasons": [],
    }
    if not n:
        stats["mean_claim_age_days"] = None
        return False, stats

    mean_age = sum(age_values) / n
    target = float(cfg["claim_age_target"])
    share_60 = sum(1 for v in age_values if v >= 60) / n
    share_90 = sum(1 for v in age_values if v >= 90) / n
    share_120 = sum(1 for v in age_values if v >= 120) / n

    stats.update(
        {
            "mean_claim_age_days": round(mean_age, 4),
            "claim_age_target": target,
            "share_claim_age_ge_60": round(share_60, 4),
            "share_claim_age_ge_90": round(share_90, 4),
            "share_claim_age_ge_120": round(share_120, 4),
        }
    )

    # Portfolio-style aggregate BWDO for summary (not used for chaos rules yet)
    bw_num = 0.0
    bw_den = 0.0
    for r in raw_rows:
        bal = r.get("out_ins_amt")
        age = r.get("claim_age_days")
        if bal is not None and age is not None and float(bal) > 0:
            bw_num += float(bal) * float(age)
            bw_den += float(bal)
    if bw_den > 0:
        stats["balance_weighted_days_outstanding"] = round(bw_num / bw_den, 4)

    reasons: list[str] = []
    factor = float(
        chaos_cfg.get(
            "mean_claim_age_factor",
            chaos_cfg.get("mean_ar_days_factor", 1.5),
        )
    )
    if mean_age > target * factor:
        reasons.append(
            f"mean_claim_age_days {mean_age:.2f} > "
            f"target*{factor} ({target * factor:.2f})"
        )
    thr60 = float(
        chaos_cfg.get(
            "share_claim_age_ge_60",
            chaos_cfg.get("share_ar_ge_60", 0.40),
        )
    )
    thr90 = float(
        chaos_cfg.get(
            "share_claim_age_ge_90",
            chaos_cfg.get("share_ar_ge_90", 0.25),
        )
    )
    thr120 = float(
        chaos_cfg.get(
            "share_claim_age_ge_120",
            chaos_cfg.get("share_ar_ge_120", 0.15),
        )
    )
    if share_60 >= thr60:
        reasons.append(
            f"share_claim_age_ge_60 {share_60:.2%} >= {thr60:.2%}"
        )
    if share_90 >= thr90:
        reasons.append(
            f"share_claim_age_ge_90 {share_90:.2%} >= {thr90:.2%}"
        )
    if share_120 >= thr120:
        reasons.append(
            f"share_claim_age_ge_120 {share_120:.2%} >= {thr120:.2%}"
        )

    stats["reasons"] = reasons
    return (len(reasons) > 0), stats
